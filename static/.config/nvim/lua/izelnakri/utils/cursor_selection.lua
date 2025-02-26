-- NOTE: Should I rename this to CursorSelection?
CursorSelection = {}

--- @return string : Returns and yanks selected text, yank is at " register
function CursorSelection.get_and_yank_selection()
  local tx, rx = require("plenary.async").control.channel.oneshot()

  vim.api.nvim_feedkeys("ygv", "n", false)
  vim.schedule(function()
    local text = vim.fn.getreg('"')
    tx(text)
  end)

  return rx()
end

--- @return string : Returns selected text
function CursorSelection.get_selection()
  local tx, rx = require("plenary.async").control.channel.oneshot()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" then
    vim.api.nvim_feedkeys("Vgv", "n", false)
    vim.schedule(function()
      local start_location = vim.api.nvim_buf_get_mark(0, "<") -- { line, col }
      local end_location = vim.api.nvim_buf_get_mark(0, ">")
      local buf_table = vim.api.nvim_buf_get_lines(0, start_location[1] - 1, end_location[1], true)

      return tx(table.concat(buf_table, "\n"))
    end)
  else
    vim.api.nvim_feedkeys("vgv", "n", false)
    vim.schedule(function()
      local start_location = vim.api.nvim_buf_get_mark(0, "<") -- { line, col }
      local end_location = vim.api.nvim_buf_get_mark(0, ">")
      local buf_table = vim.api.nvim_buf_get_text(
        0,
        start_location[1] - 1,
        start_location[2],
        end_location[1] - 1,
        end_location[2] + 1,
        {}
      )

      return tx(table.concat(buf_table, "\n"))
    end)
  end

  return rx()
end

return CursorSelection
