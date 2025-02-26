-- NOTE: Configure so it is tabpages(?) has to be mode: tabs, diagnostics: "nvim_lsp", sidebar_offset,
-- number(also maybe add keybind <S-1> etc on normal mode)
return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },

      -- { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      -- { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      -- { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
      -- { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      -- { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      -- { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      -- { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      -- { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      -- { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    },
    -- opts = {
    --   options = {
    --     -- stylua: ignore
    --     close_command = function(n) require("mini.bufremove").delete(n, false) end,
    --     -- stylua: ignore
    --     right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
    --     diagnostics = "nvim_lsp",
    --     always_show_bufferline = false,
    --     diagnostics_indicator = function(_, _, diag)
    --       local icons = require("lazyvim.config").icons.diagnostics
    --       local ret = (diag.error and icons.Error .. diag.error .. " " or "")
    --         .. (diag.warning and icons.Warn .. diag.warning or "")
    --       return vim.trim(ret)
    --     end,
    --     offsets = {
    --       {
    --         filetype = "neo-tree",
    --         text = "Neo-tree",
    --         highlight = "Directory",
    --         text_align = "left",
    --       },
    --     },
    --   },
    -- },
    config = function(_, opts)
      opts.options = {
        -- mode = "buffers", -- set to "tabs" to only show tabpages instead
        -- style_preset = bufferline.style_preset.default, -- or bufferline.style_preset.minimal,
        -- themable = true | false, -- allows highlight groups to be overriden i.e. sets highlights as default
        numbers = "ordinal", -- "none" | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        -- close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
        -- right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        -- left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
        -- middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
        -- indicator = {
        --     icon = '▎', -- this should be omitted if indicator style is not 'icon'
        --     style = 'icon' | 'underline' | 'none',
        -- },
        -- buffer_close_icon = '󰅖',
        -- modified_icon = '●',
        -- close_icon = '',
        -- left_trunc_marker = '',
        -- right_trunc_marker = '',
        -- --- name_formatter can be used to change the buffer's label in the bufferline.
        -- --- Please note some names can/will break the
        -- --- bufferline so use this at your discretion knowing that it has
        -- --- some limitations that will *NOT* be fixed.
        -- name_formatter = function(buf)  -- buf contains:
        --       -- name                | str        | the basename of the active file
        --       -- path                | str        | the full path of the active file
        --       -- bufnr (buffer only) | int        | the number of the active buffer
        --       -- buffers (tabs only) | table(int) | the numbers of the buffers in the tab
        --       -- tabnr (tabs only)   | int        | the "handle" of the tab, can be converted to its ordinal number using: `vim.api.nvim_tabpage_get_number(buf.tabnr)`
        -- end,
        -- max_name_length = 18,
        -- max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
        -- truncate_names = true, -- whether or not tab names should be truncated
        -- tab_size = 18,
        -- diagnostics = false | "nvim_lsp" | "coc",
        -- diagnostics_update_in_insert = false,
        -- -- The diagnostics indicator can be set to nil to keep the buffer name highlight but delete the highlighting
        -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
        --     return "("..count..")"
        -- end,
        -- -- NOTE: this will be called a lot so don't do any heavy processing here
        -- custom_filter = function(buf_number, buf_numbers)
        --     -- filter out filetypes you don't want to see
        --     if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
        --         return true
        --     end
        --     -- filter out by buffer name
        --     if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
        --         return true
        --     end
        --     -- filter out based on arbitrary rules
        --     -- e.g. filter out vim wiki buffer from tabline in your work repo
        --     if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
        --         return true
        --     end
        --     -- filter out by it's index number in list (don't show first buffer)
        --     if buf_numbers[1] ~= buf_number then
        --         return true
        --     end
        -- end,
        -- offsets = {
        --     {
        --         filetype = "NvimTree",
        --         text = "File Explorer" | function ,
        --         text_align = "left" | "center" | "right"
        --         separator = true
        --     }
        -- },
        -- color_icons = true | false, -- whether or not to add the filetype icon highlights
        -- get_element_icon = function(element)
        --   -- element consists of {filetype: string, path: string, extension: string, directory: string}
        --   -- This can be used to change how bufferline fetches the icon
        --   -- for an element e.g. a buffer or a tab.
        --   -- e.g.
        --   local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(element.filetype, { default = false })
        --   return icon, hl
        --   -- or
        --   local custom_map = {my_thing_ft: {icon = "my_thing_icon", hl}}
        --   return custom_map[element.filetype]
        -- end,
        -- show_buffer_icons = true | false, -- disable filetype icons for buffers
        -- show_buffer_close_icons = true | false,
        -- show_close_icon = true | false,
        -- show_tab_indicators = true | false,
        -- show_duplicate_prefix = true | false, -- whether to show duplicate buffer prefix
        -- duplicates_across_groups = true, -- whether to consider duplicate paths in different groups as duplicates
        -- persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        -- move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
        -- -- can also be a table containing 2 custom separators
        -- -- [focused and unfocused]. eg: { '|', '|' }
        -- separator_style = "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
        -- enforce_regular_tabs = false | true,
        -- always_show_bufferline = true | false,
        -- auto_toggle_bufferline = true | false,
        -- hover = {
        --     enabled = true,
        --     delay = 200,
        --     reveal = {'close'}
        -- },
        -- sort_by = 'insert_after_current' |'insert_at_end' | 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        --     -- add custom logic
        --     return buffer_a.modified > buffer_b.modified
        -- end
      }

      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd("BufAdd", {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}

-- NOTE: LazyVim config:
--
-- {
--   "akinsho/bufferline.nvim",
--   event = "VeryLazy",
--   keys = {
--     { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
--     { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
--     { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
--     { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
--     { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
--     { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
--     { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
--     { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
--     { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
--   },
--   opts = {
--     options = {
--       -- stylua: ignore
--       close_command = function(n) require("mini.bufremove").delete(n, false) end,
--       -- stylua: ignore
--       right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
--       diagnostics = "nvim_lsp",
--       always_show_bufferline = false,
--       diagnostics_indicator = function(_, _, diag)
--         local icons = require("lazyvim.config").icons.diagnostics
--         local ret = (diag.error and icons.Error .. diag.error .. " " or "")
--           .. (diag.warning and icons.Warn .. diag.warning or "")
--         return vim.trim(ret)
--       end,
--       offsets = {
--         {
--           filetype = "neo-tree",
--           text = "Neo-tree",
--           highlight = "Directory",
--           text_align = "left",
--         },
--       },
--     },
--   },
--   config = function(_, opts)
--     require("bufferline").setup(opts)
--     -- Fix bufferline when restoring a session
--     vim.api.nvim_create_autocmd("BufAdd", {
--       callback = function()
--         vim.schedule(function()
--           pcall(nvim_bufferline)
--         end)
--       end,
--     })
--   end,
-- },
--
--
--
--
--
