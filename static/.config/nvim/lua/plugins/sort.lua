return {
  {
    "sQVe/sort.nvim",
    config = function()
      require("sort").setup()
      vim.keymap.set({ "n", "v" }, "gS", "<cmd>Sort<cr>", { desc = "Sort selection", remap = true })
    end,
  },
}
