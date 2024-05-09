return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      -- table.insert(opts.ensure_installed, "markdownlint-cli2")
      table.insert(opts.ensure_installed, "selene")

      -- ensure_installed = {
      --   "ansible-language-server",
      --   "ansible-lint",
      --   "codelldb",
      --   "deno",
      --   "docker-compose-language-service",
      --   "dockerfile-language-server",
      --   "dot-language-server",
      --   "elixir-ls",
      --   "ember-language-server",
      --   "erlang-debugger",
      --   "erlang-ls",
      --   "gitui",
      --   "hadolint",
      --   "helm-ls",
      --   "js-debug-adapter",
      --   "json-lsp",
      --   "lua-language-server",
      --   "marksman",
      --   "ruby-lsp",
      --   "rust-analyzer",
      --   "shfmt",
      --   "solargraph",
      --   "solidity",
      --   "stylua",
      --   "taplo",
      --   "typescript-language-server",
      --   "yaml-language-server",
      -- },
    end,
  },
}
