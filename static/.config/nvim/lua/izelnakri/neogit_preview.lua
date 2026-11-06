-- lazygit-style preview for neogit's status screen: the file list stays on the left and a pane on the right
-- shows what the cursor is on, updating as you move. Unstaged/staged files show their diff, untracked files
-- their whole content, commits and stashes their patch. Rendered through delta (your git pager config) when
-- it's installed, else as a plain diff buffer.
--   =        toggle the preview (on by default)
--   <C-l>    jump into it to scroll / search (`/`), <C-h> back (your window keys)
-- Wired up in plugins/neogit.lua.
local M = {}

local preview = { win = nil, buf = nil, key = nil, request = 0 }
M.enabled = true

local function status_ui()
  local ok, status = pcall(function()
    return require("neogit.buffers.status").instance()
  end)
  return ok and status and status.buffer and status.buffer.ui or nil
end

-- What to show for the item under the cursor: `{ key, cmd, title }` or nil.
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
    return { key = name, title = name, cmd = { "git", "stash", "show", "--patch", "--include-untracked", name } }
  end
  local oid = item.oid or (item.commit and item.commit.oid)
  if oid then
    return { key = oid, title = oid:sub(1, 8), cmd = { "git", "show", "--stat", "--patch", oid } }
  end
  -- Repo-relative (git runs from the repo root below), so delta's headers read `src/x.rs`, not /home/...
  local path = item.name or item.escaped_path
  if not path then
    return nil
  end
  if section == "staged" then
    return { key = "staged:" .. path, title = item.name, cmd = { "git", "diff", "--cached", "--", path } }
  elseif section == "untracked" then
    -- `--no-index` against /dev/null renders the whole new file as one hunk (exit code 1 is expected).
    return { key = "new:" .. path, title = item.name, cmd = { "git", "diff", "--no-index", "--", "/dev/null", path } }
  else -- unstaged, unmerged, ...
    return { key = "work:" .. path, title = item.name, cmd = { "git", "diff", "--", path } }
  end
end

local function preview_visible()
  return preview.win ~= nil and vim.api.nvim_win_is_valid(preview.win)
end

local function placeholder()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "",
    "  Move to a file, commit or stash to preview it here.",
    "",
    "  =        hide / show this preview",
    "  <C-l>    jump in to scroll or search (/), <C-h> back",
  })
  vim.bo[buf].modifiable = false
  return buf
end

local function open_window(status_win)
  local buf = placeholder()
  -- A split would first show the status buffer twice; open it on the placeholder instead.
  preview.win = vim.api.nvim_open_win(buf, false, { split = "right", win = status_win })
  preview.buf, preview.key = buf, nil
  vim.api.nvim_win_set_width(preview.win, math.floor(vim.o.columns * 0.58))
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
  vim.api.nvim_set_current_win(status_win)
end

-- Show `text` in a fresh buffer in the preview window: through a terminal channel when it carries delta's
-- ANSI colors, else as a `diff` buffer.
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
  if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end
end

function M.refresh(force)
  if not (M.enabled and preview_visible()) then
    return
  end
  local t = target()
  if not t then
    return
  end
  if t.key == preview.key and not force then
    return
  end
  preview.key = t.key
  preview.request = preview.request + 1
  local request = preview.request
  local cwd = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1] or vim.fn.getcwd()
  if vim.v.shell_error ~= 0 then
    cwd = vim.fn.getcwd()
  end

  local cmd, ansi = t.cmd, false
  if vim.fn.executable("delta") == 1 then
    local width = vim.api.nvim_win_get_width(preview.win)
    cmd = {
      "sh",
      "-c",
      table.concat(vim.tbl_map(vim.fn.shellescape, t.cmd), " ") .. " | delta --paging=never --width=" .. width,
    }
    ansi = true
  end
  vim.system(cmd, { cwd = cwd, text = true, env = { GIT_PAGER = "cat" } }, function(result)
    vim.schedule(function()
      if request ~= preview.request then
        return -- the cursor already moved on
      end
      local out = result.stdout or ""
      if out == "" then
        out = (result.stderr ~= "" and result.stderr) or "(nothing to show)"
        ansi = false
      end
      show(out, t.title, ansi)
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
  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, { group = group, buffer = buf, callback = M.close })

  vim.keymap.set("n", "=", function()
    M.enabled = not M.enabled
    if M.enabled then
      ensure_open()
    else
      M.close()
    end
  end, { buffer = buf, desc = "Toggle the diff preview" })
end

return M
