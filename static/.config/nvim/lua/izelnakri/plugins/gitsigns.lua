return {
  {
    "lewis6991/gitsigns.nvim", -- Adds git related signs to the gutter, as well as utilities for managing changes
    opts = function(_, opts)
      opts.signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      }

      opts.on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- TODO: Navigation. Change these to my keymaps:
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Jump to next git [c]hange" })

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Jump to previous git [c]hange" })

        -- TODO: Actions. Change these to my keymaps:
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "stage git hunk" })
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "reset git hunk" })

        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
        map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
        map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "git [u]ndo stage hunk" })
        map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
        map("n", "<leader>hb", gitsigns.blame_line, { desc = "git [b]lame line" })
        map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
        map("n", "<leader>hD", function()
          gitsigns.diffthis("@")
        end, { desc = "git [D]iff against last commit" })

        map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
        map("n", "<leader>tD", gitsigns.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
      end
    end,
  },
}

-- return {
--   {
--     "lewis6991/gitsigns.nvim",
--     event = "LazyFile",
--     opts = function(_, opts)
--       opts._signs_staged_enable = true
--       opts.current_line_blame_opts = {
--         virt_text = true,
--         virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
--         delay = 250,
--         ignore_whitespace = false,
--         virt_text_priority = 100,
--       }
--       opts.attach_to_untracked = true
--       opts.on_attach = function(buffer)
--         local gs = package.loaded.gitsigns
--
--         local function map(mode, l, r, desc)
--           vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
--         end
--
--         map("n", "]h", gs.next_hunk, "Next Hunk")
--         map("n", "[h", gs.prev_hunk, "Prev Hunk")
--
--         map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
--         map("n", "<leader>ghu", gs.undo_stage_hunk, "Unstage Hunk")
--         map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
--
--         map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
--         map("n", "<leader>ghb", function()
--           gs.blame_line({ full = true })
--         end, "Blame Line")
--         map("n", "<leader>ghd", gs.diffthis, "Diff This")
--
--         map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
--         map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
--
--         map("n", "<leader>ghD", function()
--           gs.diffthis("~")
--         end, "Diff This ~")
--
--         map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
--
--         map("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle line blame")
--         map("n", "<leader>gtd", gs.toggle_deleted)
--       end
--     end,
--   },
--   {
--     "tpope/vim-fugitive",
--     keys = {
--       { "<leader>ghB", ":Git blame<CR>", "Toggle document git blame" },
--       { "<leader>gB", ":Git blame<CR>", "Toggle Git Blame for file" },
--     },
--   },
-- }
--
