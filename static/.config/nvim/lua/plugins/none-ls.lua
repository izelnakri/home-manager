-- NOTE: THIS IS THE ESSENTIAL LSP CONFIGURATION UNTIL NEOVIM SHIPS WITH LSP INTERNALLY on v0.10+ (Written on v0.9.5)
-- NOTE: This is probably not needed due to conform.nvim & nvim-lint, but I can check linters/formatters used here:
-- NOTE: also check efm-langserver
return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require("null-ls")

      -- table.insert(opts.sources, null_ls.builtins.formatting.cbfmt)
      -- table.insert(opts.sources, null_ls.builtins.diagnostics.markdownlint_cli2)

      -- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      --
      -- opts.on_attach = function(client, bufnr)
      --   if client.supports_method("textDocument/formatting") then
      --     vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      --     vim.api.nvim_create_autocmd("BufWritePre", {
      --       group = augroup,
      --       buffer = bufnr,
      --       callback = function()
      --         -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
      --         -- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
      --         vim.lsp.buf.formatting_sync()
      --       end,
      --     })
      --   end
      -- end
    end,
  },
}
