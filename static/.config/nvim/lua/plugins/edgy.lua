return {
  {
    "folke/edgy.nvim",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = function(_, opts)
      local bottom_window_size = { height = 0.6 }

      opts.keys["<c-w>k"] = function(win)
        vim.print("called")
        vim.print(win.height)
        if win.height > vim.o.lines then
          win:resize("height", -vim.o.lines)
        else
          win.old_height = win.height
          win:resize("height", vim.o.lines)
        end
      end

      opts.left = {
        {
          title = "Neo-Tree",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          pinned = true,
          open = function()
            vim.api.nvim_input("<esc><space>e")
          end,
          size = { height = 0.5 },
        },
        {
          title = "Neotest Summary",
          ft = "neotest-summary",
          filter = function(_) end,
        },
        {
          title = "Neo-Tree Git",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "git_status"
          end,
          pinned = false,
          open = "Neotree position=right git_status",
        },
        {
          title = "Neo-Tree Buffers",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "buffers"
          end,
          pinned = false,
          open = "Neotree position=top buffers",
        },
        {
          title = "Aerial",
          ft = "aerial",
          open = "AerialOpen",
        },
      }
      opts.right = {
        {
          ft = "trouble",
          filter = function(_, win)
            return vim.w[win].trouble.mode == "symbols"
          end,
        },
      }
      opts.bottom = {
        {
          ft = "man",
          open = "norm! K",
          filter = function()
            return #require("bufferline").get_elements().elements > 0
          end,
          size = { height = 0.65 },
        },
        {
          ft = "toggleterm",
          size = bottom_window_size,
          filter = function(_, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        {
          ft = "noice",
          size = bottom_window_size,
          filter = function(_, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        {
          ft = "lazyterm",
          size = bottom_window_size,
          filter = function(buf)
            return not vim.b[buf].lazyterm_cmd
          end,
        },
        {
          ft = "trouble",
          size = { height = 0.30 },
          filter = function(_, win)
            return vim.w[win].trouble.mode == "diagnostics"
          end,
        },
        {
          title = "QuickFix",
          ft = "qf",
          size = bottom_window_size,
        },
        {
          title = "Help",
          ft = "help",
          size = bottom_window_size,
          -- don't open help files in edgy that we're editing
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
        { title = "Spectre", ft = "spectre_panel", size = { height = 0.5 } },
        { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 0.5 } },
      }
    end,
  },
}

-- return {
--   "folke/edgy.nvim",
--   event = "VeryLazy",
--   opts = {
--     right = {
--         title = "TODOs",
--         ft = "markdown",
--         size = { height = 0.4 },
--         filter = function(buf, win)
--           local root_str = { "stylua.lua", ".git", ".clang-format", "pyproject.toml", "setup.py" }
--           local root_dir = vim.fs.dirname(vim.fs.find(root_str, { upward = true })[1])
--
--           local todo = "" -- Don;t
--           local todo_buffer = vim.api.nvim_buf_get_name(root_dir .. todo)
--           return todo_buffer
--         end,
--     }
--   }
-- }
