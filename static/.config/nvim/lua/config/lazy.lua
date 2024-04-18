-- TODO: DAP works for vitest, requires big setup for jest(implement it for qunit, [package.json].test big reference point | console.log doesnt work for DAP repl(?) works, for right panel| Investigate how rust struct/impl can be debugged/shown
-- TODO: Implement K - documentation scoll(without enter) and maybe go-to-definition *there as well with my doc tool*
-- TODO: colors FOR COLORS: <leader>ui to inspect what certain key is ALSO: Search Highlight groups <leader>sH | <leader>uC
-- TODO: Implement AI part. Simplify NOICE: LocationList, Quickfix, todo [Read well Trouble], Diagnostics & customize it. make scroll forward/backward c-j c-k [q ]q
-- NOTE: Still research each LSP key, research mini.pairs, mini.surround: gsa, gsd, gsr, <leader>cs outline
-- NOTE: neodev customization(<leader>sl), maybe add edgy.nvim for prettier look, THIS GOES <leader>cS on hovered over items make the panel easy to read change it
-- check https://github.com/vxpm/ferris.nvim for rust doc opener, still check httrack: https://www.reddit.com/r/brave_browser/comments/15q3n7o/is_there_a_way_to_save_a_website_for_offline/

-- Keys to remember: <l-xx> [b ]b <l-cr> <l-sh> <wgf> navigate for file , <l-cr> for replacing code node, <C-q> visual block mo, <C-e> abort cmp
-- and wincmd file and remove it from bottom left?
-- macro q (smt)| q | 3@q
-- C-] moves in vim docs, C-t goes back
-- <leader>tr | <leader>tl | ]e [e , r reruns, a attaches test result
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

    { import = "lazyvim.plugins.extras.coding.codeium" },
    { import = "lazyvim.plugins.extras.coding.copilot" },
    {
      import = "lazyvim.plugins.extras.coding.native_snippets", -- NOTE: Maybe add friendly snippets
    },
    { import = "lazyvim.plugins.extras.coding.yanky" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.dap.nlua" },

    { import = "lazyvim.plugins.extras.test.core" },

    { import = "lazyvim.plugins.extras.editor.aerial" },
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
    { import = "lazyvim.plugins.extras.ui.edgy" },

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
