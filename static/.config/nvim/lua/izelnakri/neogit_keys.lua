-- lazygit muscle memory on neogit's status screen, on top of neogit's own keys (s/u/x/c/P/... all still work):
--   <cr>     on a file: expand / collapse its hunks inline, to stage single hunks or (V) lines; on a diff
--            line, commit or stash: open it
--   e        open the file at the cursor line in its own tab (lazygit's `e`); :q / :wq there comes back
--            to this status screen, refreshed. On a commit or stash it opens that, like neogit's own `e`.
--   a        stage everything (untracked too), or unstage everything when nothing is left to stage
--   <space>  stage / unstage the file, hunk or visual selection under the cursor. Only in `gg` / `neogit`
--            from a shell: inside nvim, <space> is your <leader>, so use s / u there.
-- Wired up in plugins/neogit.lua (FileType NeogitStatus).
local M = {}

local function status_ui()
  local ok, status = pcall(function()
    return require("neogit.buffers.status").instance()
  end)
  return ok and status and status.buffer and status.buffer.ui or nil
end

local function section_under_cursor(ui)
  local node = ui and ui:get_current_section()
  return node and node.options.section
end

-- Runs neogit's own buffer mappings (s, u, <tab>, e, ...), so their behaviour is exactly neogit's.
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "m", false)
end

-- Runs one of neogit's status actions (buffers/status/actions.lua) directly, e.g. "n_goto_file".
local function run_action(name)
  local status = require("neogit.buffers.status").instance()
  if status then
    require("neogit.buffers.status.actions")[name](status)()
  end
end

-- neogit's GoToFile closes the status screen and edits the file in its place, so quitting the file leaves
-- nothing to return to. Open it in a new tab instead (neogit's TabOpen, same cursor line) and, when that
-- tab is closed, focus the status screen again.
local function edit_and_return(buf)
  local tab_count = #vim.api.nvim_list_tabpages()
  run_action("n_tab_open")
  vim.schedule(function()
    if #vim.api.nvim_list_tabpages() == tab_count then
      return -- nothing opened
    end
    local edit_tab = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_create_autocmd("TabClosed", {
      callback = function()
        if vim.api.nvim_tabpage_is_valid(edit_tab) then
          return false -- another tab closed; keep waiting
        end
        vim.schedule(function()
          local win = vim.api.nvim_buf_is_valid(buf) and vim.fn.win_findbuf(buf)[1]
          if win then
            vim.api.nvim_set_current_win(win)
            pcall(function()
              require("neogit.buffers.status").instance():dispatch_refresh(nil, "edit_returned")
            end)
          end
        end)
        return true
      end,
    })
  end)
end

local FILE_SECTIONS = { staged = true, unstaged = true, untracked = true, unmerged = true }

function M.attach(buf)
  -- Scheduled so these win over the buffer-local mappings neogit sets on the same buffer.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local function map(mode, lhs, fn, desc)
      vim.keymap.set(mode, lhs, fn, { buffer = buf, desc = desc, nowait = true })
    end

    map("n", "<cr>", function()
      local ui = status_ui()
      local item = ui and ui:get_item_under_cursor()
      local location = ui and ui:get_cursor_location()
      local on_file = item and FILE_SECTIONS[section_under_cursor(ui)] and not (location and location.hunk)
      if on_file then
        feed("<tab>")
      elseif item and item.absolute_path then
        edit_and_return(buf)
      else
        run_action("n_goto_file") -- commit, stash, ...
      end
    end, "Expand file hunks / open the line, commit or stash")

    map("n", "e", function()
      local ui = status_ui()
      local item = ui and ui:get_item_under_cursor()
      if item and item.absolute_path then
        edit_and_return(buf)
      else
        run_action("n_goto_file")
      end
    end, "Edit the file in a tab; :q comes back here")

    map("n", "a", function()
      local git = require("neogit.lib.git")
      if git.status.anything_unstaged() or #git.repo.state.untracked.items > 0 then
        feed("<c-s>")
      else
        feed("U")
      end
    end, "Stage all / unstage all")

    if vim.g.neogit_standalone == 1 then
      map({ "n", "x" }, "<space>", function()
        local section = section_under_cursor(status_ui())
        if section == "staged" then
          feed("u")
        elseif FILE_SECTIONS[section] then
          feed("s")
        end
      end, "Stage / unstage (lazygit's space)")
    end
  end)
end

return M
