return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    keys = function()
      return {}
    end,
  },
  {
    "David-Kunz/cmp-npm",
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    event = { "InsertEnter", "CmdlineEnter" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      table.insert(opts.sources, { name = "emoji" })
      table.insert(opts.sources, { name = "npm", keyword_length = 4 })

      local cmp = require("cmp")
      local scroll_down_or_initiate_completion = function()
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
      end

      -- TODO: Should this be only on insert mode?
      opts.mapping = cmp.mapping.preset.insert({
        ["<C-f>"] = function()
          if cmp.visible() then
            return (cmp.mapping.confirm({ select = true }))()
          else
            return (cmp.mapping.complete())()
          end
        end,
        ["<CR>"] = cmp.mapping(function(fallback)
          fallback()
        end),
        ["<C-j>"] = cmp.mapping({
          i = scroll_down_or_initiate_completion,
          c = scroll_down_or_initiate_completion,
          n = scroll_down_or_initiate_completion,
        }),
        ["<C-k>"] = cmp.mapping({
          i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          fallback()
        end),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          fallback()
        end),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
      })
    end,
  },
}
