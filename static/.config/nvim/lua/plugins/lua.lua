return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "lua-language-server",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["lua-language-server"] = {},
      },
    },
  },
}

-- dap / debugger support, if this is ever possible or needed.
-- extend neotest, if this is ever needed, for most people I suspect not needed.
-- linting, if this is ever needed.
-- maybe enhance nvim-cmp behavior, rust lang extension does smt with nvim-cmp, other language extensions don't.
