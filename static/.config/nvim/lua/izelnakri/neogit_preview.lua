-- lazygit-style preview for neogit's status screen: the file list stays on the left and a pane on the right
-- shows what the cursor is on, updating as you move. Unstaged/staged files show their diff, untracked files
-- their whole content, commits and stashes their patch.
--   |            cycle the style: delta unified / delta side-by-side / difftastic (syntax-aware)
--   = / +        hide or show the preview / make it wider or narrower
--   <C-d> <C-u>  scroll it from the list (like lazygit's main panel); <C-l> to jump in, <C-h> back
-- Wired up in plugins/neogit.lua.
local M = {}

local preview = { win = nil, buf = nil, key = nil, request = 0, wide = false }
M.enabled = true

local STYLES = { "unified", "split", "difftastic" }
local STYLE_LABELS = { unified = "delta", split = "delta side-by-side", difftastic = "difftastic", plain = "diff" }
M.style = nil -- nil: side-by-side when the pane is wide enough, else unified

local function status_ui()
  local ok, status = pcall(function()
    return require("neogit.buffers.status").instance()
  end)
  return ok and status and status.buffer and status.buffer.ui or nil
end

-- What to show for the item under the cursor: `{ key, title, git = {args...} }` or nil.
local function target()
  local ui = status_ui()
  if not ui then
    return nil
  end
  local item = ui:get_item_under_cursor()
  local section_node = ui:get_current_section()
  local section = section_node and section_node.options.section
  if not item then
    return nil
  end

  if section == "stashes" and item.idx then
    local name = ("stash@{%s}"):format(item.idx)
    return { key = name, title = name, git = { "stash", "show", "--patch", "--include-untracked", name } }
  end
  local oid = item.oid or (item.commit and item.commit.oid)
  if oid then
    return { key = oid, title = oid:sub(1, 8), git = { "show", "--stat", "--patch", oid } }
  end
  -- Repo-relative (git runs from the repo root below), so headers read `src/x.rs`, not /home/...
  local path = item.name or item.escaped_path
  if not path then
    return nil
  end
  if section == "staged" then
    return { key = "staged:" .. path, title = path, git = { "diff", "--cached", "--", path } }
  elseif section == "untracked" then
    -- `--no-index` against /dev/null renders the whole new file as one hunk (exit code 1 is expected).
    return { key = "new:" .. path, title = path .. " (new)", git = { "diff", "--no-index", "--", "/dev/null", path } }
  else -- unstaged, unmerged, ...
    return { key = "work:" .. path, title = path, git = { "diff", "--", path } }
  end
end

local function preview_visible()
  return preview.win ~= nil and vim.api.nvim_win_is_valid(preview.win)
end

local function current_style(width)
  local style = M.style or (width >= 150 and "split" or "unified")
  if style == "difftastic" and vim.fn.executable("difft") ~= 1 then
    style = "unified"
  end
  if style ~= "difftastic" and vim.fn.executable("delta") ~= 1 then
    style = "plain"
  end
  return style
end

local function set_winbar(title)
  if not preview_visible() then
    return
  end
  local style = current_style(vim.api.nvim_win_get_width(preview.win))
  local name = (title or "preview"):gsub("%%", "%%%%")
  vim.wo[preview.win].winbar = " %#Title#"
    .. name
    .. "%* · "
    .. STYLE_LABELS[style]
    .. "%=%#Comment#| style  = hide  + width  ^d/^u scroll  ^l focus %*"
end

local function placeholder()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "",
    "  Move to a file, commit or stash to preview it here.",
    "",
    "  |            delta / delta side-by-side / difftastic",
    "  =  +         hide / wider",
    "  <C-d> <C-u>  scroll this preview from the list",
    "  <C-l>        jump in to scroll or search (/), <C-h> back",
  })
  vim.bo[buf].modifiable = false
  return buf
end

local function width_for(status_win)
  local total = vim.api.nvim_win_get_width(status_win)
    + (preview_visible() and vim.api.nvim_win_get_width(preview.win) or 0)
  return math.floor(total * (preview.wide and 0.75 or 0.58))
end

local function open_window(status_win)
  local buf = placeholder()
  -- A split would first show the status buffer twice; open it on the placeholder instead.
  preview.win = vim.api.nvim_open_win(buf, false, { split = "right", win = status_win })
  preview.buf, preview.key = buf, nil
  vim.api.nvim_win_set_width(preview.win, width_for(status_win))
  for option, value in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    wrap = false,
    cursorline = false,
    winfixwidth = true,
  }) do
    vim.wo[preview.win][option] = value
  end
  set_winbar(nil)
end

-- Show `text` in a fresh buffer in the preview window: through a terminal channel when it carries ANSI
-- colors (delta, difftastic), else as a `diff` buffer.
local function show(text, title, ansi)
  if not preview_visible() then
    return
  end
  local old = preview.buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  if ansi then
    local chan = vim.api.nvim_open_term(buf, {})
    vim.api.nvim_chan_send(chan, (text:gsub("\r?\n", "\r\n")))
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
    vim.bo[buf].filetype = "diff"
    vim.bo[buf].modifiable = false
  end
  pcall(vim.api.nvim_buf_set_name, buf, "neogit-preview://" .. title .. "#" .. preview.request)
  vim.api.nvim_win_set_buf(preview.win, buf)
  vim.api.nvim_win_set_cursor(preview.win, { 1, 0 })
  preview.buf = buf
  set_winbar(title)
  if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end
end

local function repo_root()
  local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
  return (vim.v.shell_error == 0 and root) or vim.fn.getcwd()
end

function M.refresh(force)
  if not (M.enabled and preview_visible()) then
    return
  end
  local t = target()
  if not t then
    return
  end
  local width = vim.api.nvim_win_get_width(preview.win)
  local style = current_style(width)
  local key = t.key .. "|" .. style .. "|" .. width
  if key == preview.key and not force then
    return
  end
  preview.key = key
  preview.request = preview.request + 1
  local request = preview.request

  local git = { "git", "-c", "color.ui=never" }
  local args = vim.deepcopy(t.git)
  local env = { GIT_PAGER = "cat" }
  local cmd
  if style == "difftastic" then
    -- difftastic runs as git's external diff, so it sees whole files and diffs them by syntax.
    table.insert(args, 2, "--ext-diff")
    env.GIT_EXTERNAL_DIFF = "difft"
    env.DFT_COLOR = "always"
    env.DFT_WIDTH = tostring(width)
    cmd = vim.list_extend(git, args)
  elseif style == "plain" then
    cmd = vim.list_extend(git, args)
  else
    local delta = "delta --paging=never --width=" .. width .. (style == "split" and " --side-by-side" or "")
    cmd = {
      "sh",
      "-c",
      table.concat(vim.tbl_map(vim.fn.shellescape, vim.list_extend(git, args)), " ") .. " | " .. delta,
    }
  end
  local ansi = style ~= "plain"

  vim.system(cmd, { cwd = repo_root(), text = true, env = env }, function(result)
    vim.schedule(function()
      if request ~= preview.request then
        return -- the cursor already moved on
      end
      local out = result.stdout or ""
      local is_ansi = ansi
      if out == "" then
        out = (result.stderr ~= "" and result.stderr) or "(nothing to show)"
        is_ansi = false
      end
      show(out, t.title, is_ansi)
    end)
  end)
end

local pending = nil
local function refresh_soon()
  -- Debounce: holding j/k redraws once, where you stop.
  if pending then
    pending:stop()
  end
  pending = vim.defer_fn(function()
    pending = nil
    M.refresh(false)
  end, 60)
end

function M.close()
  if preview_visible() then
    pcall(vim.api.nvim_win_close, preview.win, true)
  end
  preview.win, preview.key = nil, nil
end

local function scroll(keys)
  if preview_visible() then
    vim.api.nvim_win_call(preview.win, function()
      vim.cmd.normal({ vim.api.nvim_replace_termcodes(keys, true, false, true), bang = true })
    end)
  end
end

--- Attach to a neogit status buffer (FileType NeogitStatus).
function M.attach(buf)
  local function ensure_open()
    if M.enabled and not preview_visible() then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        open_window(win)
        M.refresh(true)
      end
    end
  end
  vim.schedule(ensure_open)

  local group = vim.api.nvim_create_augroup("NeogitPreview" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", { group = group, buffer = buf, callback = refresh_soon })
  -- After staging/unstaging the same row can show different content, so redraw on neogit's refreshes.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NeogitStatusRefreshed",
    callback = function()
      if vim.api.nvim_get_current_buf() == buf then
        M.refresh(true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      local win = vim.fn.bufwinid(buf)
      if preview_visible() and win ~= -1 then
        vim.api.nvim_win_set_width(preview.win, width_for(win))
        M.refresh(true)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, { group = group, buffer = buf, callback = M.close })

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc, nowait = true })
  end
  map("=", function()
    M.enabled = not M.enabled
    if M.enabled then
      ensure_open()
    else
      M.close()
    end
  end, "Toggle the diff preview")
  map("|", function()
    local width = preview_visible() and vim.api.nvim_win_get_width(preview.win) or 0
    local idx = 0
    for i, style in ipairs(STYLES) do
      if style == current_style(width) then
        idx = i
      end
    end
    M.style = STYLES[idx % #STYLES + 1]
    vim.notify("Preview: " .. STYLE_LABELS[M.style], vim.log.levels.INFO, { title = "neogit" })
    M.refresh(true)
  end, "Cycle preview style: delta / side-by-side / difftastic")
  map("+", function()
    preview.wide = not preview.wide
    local win = vim.fn.bufwinid(buf)
    if preview_visible() and win ~= -1 then
      vim.api.nvim_win_set_width(preview.win, width_for(win))
      M.refresh(true)
    end
  end, "Widen / narrow the preview")
  map("<C-d>", function()
    scroll("<C-d>")
  end, "Scroll the preview down")
  map("<C-u>", function()
    scroll("<C-u>")
  end, "Scroll the preview up")
end

return M
