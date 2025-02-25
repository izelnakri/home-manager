return {
  {
    "vuki656/package-info.nvim",
    event = { "BufRead package.json" },
    opts = function(_, opts)
      local package_info = require("package-info")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<leader>ns"] = package_info.show(),
        ["<leader>np"] = package_info.change_version(),
        ["<leader>ni"] = package_info.install(),
      })
    end,
  },
}
