-- TODO: Help window half way down, InspectTree, When there are conform errors(show it small down)
-- Find the trigger to open right with content
-- Open a specific buffer on the right(for AI in the future)
return {
  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      local edgy_idx = LazyVim.plugin.extra_idx("ui.edgy")
      local aerial_idx = LazyVim.plugin.extra_idx("editor.aerial")

      if edgy_idx and edgy_idx > aerial_idx then
        LazyVim.warn("The `edgy.nvim` extra must be **imported** before the `aerial.nvim` extra to work properly.", {
          title = "LazyVim",
        })
      end

      table.insert(opts.left, {
        title = "Aerial",
        ft = "aerial",
        pinned = true,
        open = "AerialOpen",
      })
    end,
  },
  -- {
  --   "stevearc/aerial.nvim",
  --   dependencies = { "folke/edgy.nvim" },
  --   keys = {
  --     {
  --       "<leader>cs",
  --       function()
  --         require("aerial").toggle({ focus = true })
  --       end,
  --       desc = "Aerial (Symbols)",
  --     },
  --   },
  -- },
}
