vim.cmd([[
  function! OpenMarkdownBrowserOnTheRight(url)
    let active_window = system('hyprctl -j activeworkspace | jq .id')

    execute '!brave ' . a:url
    execute '!hyprctl dispatch movetoworkspacesilent ' . substitute(active_window, '\n', '', 'g') . ',title:Brave'
    execute '!hyprctl dispatch swapwindow r'
  endfunction
]])

return {
  {
    "iamcco/markdown-preview.nvim",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
    },
    event = "BufRead",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    opts = function()
      vim.o.updatetime = 10 -- NOTE: Makes preview refresh faster
      vim.g.mkdp_auto_start = 1
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_browserfunc = "OpenMarkdownBrowserOnTheRight"
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- TODO: Maybe use deno_lint for diagnostics & formatting if it has --fix option(that way I can remove dprint dep)
      -- TODO: change this in future releases of NeoVim(with better LSP support), when format on save is supported:
      opts.formatters_by_ft.markdown = { "dprint", "cbfmt" } -- TODO: This expects dprint to be installed & configured locally, it picks up local config
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      -- N// OTE: markdownlint-cli2 support:
      -- local linter = require("lint")
      -- local efm = "%f:%l:%c %m,%f:%l %m"
      --
      -- linter.linters["markdownlint-cli2"] = {
      --   name = "markdownlint-cli2",
      --   cmd = "markdownlint-cli2",
      --   ignore_exitcode = true,
      --   stream = "stderr",
      --   parser = require("lint.parser").from_errorformat(efm, {
      --     source = "markdownlint",
      --     severity = vim.diagnostic.severity.WARN,
      --   }),
      -- }

      -- TODO: remove this in future releases of NeoVim(with better LSP support), so nested languages can be linted:
      opts.linters_by_ft.markdown = {}
      -- TO debug: null_ls.get_sources()
      local null_ls = require("null-ls")

      null_ls.disable("markdownlint")
    end,
  },
}
