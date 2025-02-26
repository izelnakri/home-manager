-- TODO: instead add individual mini plugins for speed
return {
  {
    "echasnovski/mini.nvim", -- Collection of various small independent plugins/modules
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require("mini.ai").setup({ n_lines = 500 }) -- NOTE: Check n_lines config

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require("mini.surround").setup()

      -- NOTE: LazyVIm has mini.pairs, mini.comment

      -- Simple and easy statusline, maybe remove it:
      local statusline = require("mini.statusline")

      statusline.setup({ use_icons = vim.g.have_nerd_font })

      -- cursor section location to LINE:COLUMN:
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return "%2l:%-2v"
      end
    end,
  },
  {
    "echasnovski/mini.bufremove",
    keys = {
      {
        "<leader>bd",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "Delete Buffer",
      },
      -- stylua: ignore
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
    },
  },
}

-- TODO: From LazyVim config:

-- -- buffer remove
-- {
--   "echasnovski/mini.bufremove",
--
--   keys = {
--     {
--       "<leader>bd",
--       function()
--         local bd = require("mini.bufremove").delete
--         if vim.bo.modified then
--           local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
--           if choice == 1 then -- Yes
--             vim.cmd.write()
--             bd(0)
--           elseif choice == 2 then -- No
--             bd(0, true)
--           end
--         else
--           bd(0)
--         end
--       end,
--       desc = "Delete Buffer",
--     },
--     -- stylua: ignore
--     { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
--   },
-- },

-- -- Active indent guide and indent text objects. When you're browsing
-- -- code, this highlights the current level of indentation, and animates
-- -- the highlighting.
-- {
--   "echasnovski/mini.indentscope",
--   version = false, -- wait till new 0.7.0 release to put it back on semver
--   event = "LazyFile",
--   opts = {
--     -- symbol = "▏",
--     symbol = "│",
--     options = { try_as_border = true },
--   },
--   init = function()
--     vim.api.nvim_create_autocmd("FileType", {
--       pattern = {
--         "help",
--         "alpha",
--         "dashboard",
--         "neo-tree",
--         "Trouble",
--         "trouble",
--         "lazy",
--         "mason",
--         "notify",
--         "toggleterm",
--         "lazyterm",
--       },
--       callback = function()
--         vim.b.miniindentscope_disable = true
--       end,
--     })
--   end,
-- },

-- TODO: add this:
-- -- MiniMap.refresh() needed when the window is resized
-- return {
--   {
--     "echasnovski/mini.map",
--     config = function()
--       local map = require("mini.map")
--       map.setup({
--         integrations = {
--           map.gen_integration.builtin_search(),
--           map.gen_integration.gitsigns(),
--           map.gen_integration.diagnostic(),
--         },
--       })
--       MiniMap.open()
--     end,
--   },
-- }
