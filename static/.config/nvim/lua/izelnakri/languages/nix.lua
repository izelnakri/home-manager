-- NOTE: make this work/configure and clean it up:
return {}
-- return {
--   -- Extend auto completion nvim-cmp stuff from lazyvim.plugins.extras.lang.rust
--   {
--     "nvim-treesitter/nvim-treesitter",
--     opts = function(_, opts)
--       opts.ensure_installed = opts.ensure_installed or {}
--       vim.list_extend(opts.ensure_installed, { "nix" })
--     end,
--   },
--   {
--     "neovim/nvim-lspconfig",
--     opts = {
--       servers = {
--         nil_ls = {},
--       },
--     },
--   },
--   {
--     "stevearc/conform.nvim",
--     optional = true,
--     opts = function(_, opts)
--       opts.formatters_by_ft.nix = { "nixfmt", "statix" } -- NOTE: remove nixfmt
--     end,
--   },
--   {
--     "mfussenegger/nvim-lint",
--     opts = function(_, opts)
--       opts.linters_by_ft.nix = { "statix" }
--     end,
--   },
--   -- Ensure nix debugger by extending mason
--   -- Add something like rustaceanvim for nix or maybe on nvim-dap like ruby does it
--   -- Extend neotest, rust does with list_extend on opts with require("rustaceanvim.neotest")
--   -- Sometimes nvim-lint also exists
--   -- {
--   --   "mfussenegger/nvim-lint",
--   --   optional = true,
--   --   opts = function(_, opts)
--   --     if vim.fn.executable("credo") == 0 then
--   --       return
--   --     end
--   --     opts.linters_by_ft = {
--   --       elixir = { "credo" },
--   --     }
--   --   end,
-- }
