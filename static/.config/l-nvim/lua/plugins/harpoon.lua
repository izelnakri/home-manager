-- TODO: instead <leader>fb does this BUT how to copy file path(?) also delete doesnt work, but has preview and typeahead  filter
-- Also instead make an index of files and hit a number to go to that file
return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local keys = {
        {
          "<leader>a",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Harpoon File",
        },
        {
          "<C-e>",
          function()
            -- items = { {
            --     context = {
            --       col = 0,
            --       row = 6
            --     },
            --     value = "flake.lock"
            --   }, {
            --     context = {
            --       col = 0,
            --       row = 46
            --     },
            --     value = "static/.config/nvim/lua/config/lazy.lua"
            --   }, {

            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon Quick Menu",
        },
      }

      -- TODO: Make them only for harpoon filetype
      for i = 1, 15 do
        -- TODO: make this without leader
        table.insert(keys, {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Harpoon to File " .. i,
        })
      end
      return keys
    end,
  },
}

-- local mark = require(builtin.help_tags"harpoon.mark")
-- local ui = require("harpoon.ui")
--
-- vim.keymap.set("n", "<leader>a", mark.add_file)
-- vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
--
-- vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
-- vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
-- vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
-- vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
