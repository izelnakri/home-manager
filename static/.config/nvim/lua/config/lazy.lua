-- TODO: devdocs solution, styling, ai and language linting/debugging tests for each project
-- TODO: add 'metakirby5/codi.vim' if inlay hinting isnt sufficient.
--
-- TODO: Implement K - documentation scoll(without enter) and go-to-definition
-- TODO: colors & snippets
-- Keys to remember: <l-xx> [b ]b <l-cr> <l-sh> <wgf> navigate for file , <l-cr> for replacing code node, <C-q> visual block mo, <C-e> abort cmp
-- and wincmd file and remove it from bottom left?
-- macro q (smt)| q | 3@q
-- C-] moves in vim docs, C-t goes back
-- <leader>tr | <leader>tt | <leader>ts | <leader>tl | ]e [e , r reruns, a attaches test result
-- <leader>td debug nearest test | yellow arrow -> <leader>dO step over | <leader>dt terminate
-- :InspectTree, <C-space> | <bs>, ]f, va=

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
    {
      import = "lazyvim.plugins.extras.coding.native_snippets",
    },
    {
      import = "lazyvim.plugins.extras.coding.yanky",
    },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.dap.nlua" },

    { import = "lazyvim.plugins.extras.editor.aerial" },
    { import = "lazyvim.plugins.extras.editor.leap" },
    { import = "lazyvim.plugins.extras.editor.navic" },
    { import = "lazyvim.plugins.extras.editor.trouble-v3" },

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

    -- TODO: check ~/Github/poem-tutorial/src/main data structure debugging functionality, implement it here
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
