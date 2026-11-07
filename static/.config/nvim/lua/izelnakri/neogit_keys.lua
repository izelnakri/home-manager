-- lazygit muscle memory on neogit's status screen, on top of neogit's own keys (s/u/x/c/P/... all still work):
--   <cr>     on a file: expand / collapse its hunks inline, to stage single hunks or (V) lines; on a diff
--            line, commit or stash: open it
--   e        open the file at the cursor line (lazygit's `e`)
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
      feed(on_file and "<tab>" or "e")
    end, "Expand file hunks / open the line, commit or stash")

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
