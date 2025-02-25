-- TODO: Study: https://github.com/neovim/nvim-lspconfig:
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
      },

      -- https://github.com/neovim/nvim-lspconfig
      -- workspace.maxPreload = 10000 The maximum amount of files that can be diagnosed. More files will require more RAM.
      -- workspace.preloadFileSize = 1000 Files larger than this value (in KB) will be skipped when loading for workspace diagnosis.

      -- settings = {},
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft.lua = { "stylua" }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft.lua = { "selene" }
    end,
  },

  {
    "jbyuki/one-small-step-for-vimkind",
    opts = function(_) -- NOTE: use opts
      local dap = require("dap")

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }

      -- dap.adapters.nlua = function(callback, config)
      --   -- callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
      -- end
    end,
  },
}

-- selene, then select std: vim like trouble.nvim does,
-- it also uses stylua.toml and .lua-format(?) and lua_ls
-- TODO: read vim.toml of trouble.nvim

-- dap / debugger support, if this is ever possible or needed.
-- extend neotest, if this is ever needed, for most people I suspect not needed.
-- linting, if this is ever needed.
-- maybe enhance nvim-cmp behavior, rust lang extension does smt with nvim-cmp, other language extensions don't.
