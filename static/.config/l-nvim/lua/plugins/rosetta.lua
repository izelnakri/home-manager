-- local a = require("plenary.async.async")
-- local control = require("plenary.async.control")
-- local channel = control.channel

-- local tx, rx = channel.oneshot()

-- tx()

-- rx()

-- TODO: local co = coroutine.running()

-- TODO: coroutine.yield is await
Custom = {}
-- NOTE: there is also nvim_buf_attach
function Custom:yankAndGetSelection()
  vim.api.nvim_feedkeys("ygv", "n", false)
  vim.schedule(function()
    local text = vim.fn.getreg('"')
    LazyVim.notify(text)
  end)
end

function Custom:getSelection()
  local result = "wuha"
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" then
    vim.api.nvim_feedkeys("Vgv", "n", false)
    vim.schedule(function()
      local start_location = vim.api.nvim_buf_get_mark(0, "<") -- { line, col }
      local end_location = vim.api.nvim_buf_get_mark(0, ">")

      vim.api.nvim_buf_get_lines(0, start_location[1] - 1, end_location[1], true)
    end)
  else
    vim.api.nvim_feedkeys("vgv", "n", false)
    vim.schedule(function()
      local start_location = vim.api.nvim_buf_get_mark(0, "<") -- { line, col }
      local end_location = vim.api.nvim_buf_get_mark(0, ">")

      vim.api.nvim_buf_get_text(
        0,
        start_location[1] - 1,
        start_location[2],
        end_location[1] - 1,
        end_location[2] + 1,
        {}
      )
    end)
  end

  print("print thiiiiiis")

  return result
end

-- nvim_buf_get_text({buffer}, {start_row}, {start_col}, {end_row}, {end_col},
--                   {opts})

vim.keymap.set({ "v" }, "<C-u>", function()
  local text = Custom.getSelection()

  LazyVim.notify(text)
end, { remap = true })

vim.keymap.set({ "v" }, "<C-x>", function()
  vim.cmd([[marks]])
end, { remap = true })

return {}

-- vim.ui.input({ prompt = "Enter value for this: " }, function(input)
--   vim.print("input is " .. input)
-- end)

-- vim.ui.select({ "tabs", "spaces" }, {
--   prompt = "Select tabs or spaces:",
--   format_item = function(item)
--  nvim_get_visual_selection   return "I'd like to choose " .. item
--   end,
-- }, function(choice)
--   vim.print("choice is " .. choice)
-- end)
--
-- local bufnr = vim.api.nvim_create_buf(false, true) -- or 1164 (nvim_get_current_buf())
-- vim.api.nvim_buf_attach(0, false, {
--  on_lines = function(_, _, _, first_line, last_line)
--    local lines = vim.api.nvim_buf_get_lines(0, first_line, last_line, false)
--    -- NOTE: or do vim.schedule here only
--    vim.schedule(function() vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines) end)
--  end
--})
