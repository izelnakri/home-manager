-- TODO: Build a split repl on keybind, based on debug.debug (with context ideally)
local Utils = require("izelnakri.utils")
local keymap = vim.keymap.set

-- TODO: Make this a global plugin for languages
-- TODO: Make it <leader>(e)xecute AND these: file, line, selection, [p]rint file, [p]rint line, [p]rint selection
-- NOTE: or <leader>x instead of <leader>e

-- TODO: all these need to get this new redir stuff for a SPLIT
keymap("n", "<C-x>", "<cmd>.lua<CR>", { desc = "Execute the current line" })
keymap("n", "<leader><leader>x", "<cmd>source<CR>", { desc = "Execute the current file" }) -- % current file removed

keymap("v", "<leader><leader>x", function()
  require("plenary.async").run(function()
    local text = CursorSelection.get_selection()
    if text and text ~= "" then
      -- TODO: start redirect
      loadstring(text)()
      -- TODO: if there are stdout or stderr since the command display them on the right side as well

      --TODO: end redirect
      --TODO: if there is content show it on the right side, if split exists
    end
  end)
end, { desc = "Execute highlighted area" })

-- TODO: on_save check lint, if lint passes run execute_test_function
-- TODO: on_save either execute _spec OR Tell there is no _spec file to run tests, Do you want to create: xxx/y_spec.lua? then hit
