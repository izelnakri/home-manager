return {
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = function(_, opts)
      opts._signs_staged_enable = true
      opts.current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 250,
        ignore_whitespace = false,
        virt_text_priority = 100,
      }
      opts.attach_to_untracked = true
      opts.on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        map("n", "]h", gs.next_hunk, "Next Hunk")
        map("n", "[h", gs.prev_hunk, "Prev Hunk")

        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Unstage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")

        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, "Blame Line")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")

        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")

        map("n", "<leader>ghD", function()
          gs.diffthis("~")
        end, "Diff This ~")

        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")

        map("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>gtd", gs.toggle_deleted)
      end
    end,
  },
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>ghB", ":Git blame<CR>", "Toggle document git blame" },
      { "<leader>gB", ":Git blame<CR>", "Toggle Git Blame for file" },
    },
  },
}
