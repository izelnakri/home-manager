-- TODO: Implement K - documentation scoll(without enter) and go-to-definition
-- TODO: colors & snippets, missing plugins lookup, finish masonry
-- Keys to remember: <l-xx> <l-fb> [b ]b <l-cr> <l-st> <l-sh> <wgf> navigate for file , <l-cr> for replacing code node, <C-q> visual block mo, <C-e> abort cmp
-- <l-ft> Terminal
-- and wincmd file and remuve it from bottom left?
-- macro q (smt)| q | 3@q
-- C-] moves in vim docs, C-t goes back

-- echasnovski/mini.trailspace = to trim whitespace, probably not needed
-- nvim-cmp big deal, check all plugins: https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "gruvbox" } },
    { import = "lazyvim.plugins.extras.coding.codeium" }, -- Add Auth
    { import = "lazyvim.plugins.extras.coding.native_snippets" },
    { import = "lazyvim.plugins.extras.coding.yanky" },

    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.dap.nlua" },

    { import = "lazyvim.plugins.extras.editor.aerial" }, -- NOTE: Maybe outline is better: { import = "lazyvim.plugins.extras.editor.outline" },
    { import = "lazyvim.plugins.extras.editor.leap" },
    { import = "lazyvim.plugins.extras.editor.mini-diff" }, -- Note: https://github.com/lewis6991/gitsigns.nvim better(?) - YES: utilize these keymaps: https://www.youtube.com/watch?v=6pAG3BHurdM&list=PLnu5gT9QrFg36OehOdECFvxFFeMHhb_07&index=11
    { import = "lazyvim.plugins.extras.editor.navic" },

    { import = "lazyvim.plugins.extras.lang.ansible" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.elixir" },
    { import = "lazyvim.plugins.extras.lang.helm" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.ruby" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.yaml" },

    -- import any extras modules here
    -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
    -- import/override with your plugins
    -- TODO: Learn Trouble & Trouble v3
    -- { import = "lazyvim.plugins.extras.util.gitui" },
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
