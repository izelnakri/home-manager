return {
  {
    "folke/trouble.nvim",
    branch = "dev",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("Trouble", { clear = true }),
        callback = function()
          local trouble = require("trouble")
          local item = vim.diagnostic.get(0)[1]

          if item then
            vim.cmd([[Trouble diagnostics toggle filter.buf=0]])
            -- trouble.open("diagnostics", )
          else
            trouble.close()
          end
        end,
      })
      opts.auto_close = true
      opts.auto_preview = false
    end,
  },
}

-- { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
-- { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
-- {
--   "<leader>cS",
--   "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
--   desc = "LSP references/definitions/... (Trouble)",
-- },
-- { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
-- { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },

-- Trouble [mode]: open the list

-- document_diagnostics: document diagnostics from the builtin LSP client
-- workspace_diagnostics: workspace diagnostics from the builtin LSP client
-- lsp_references: references of the word under the cursor from the builtin LSP client
-- lsp_definitions: definitions of the word under the cursor from the builtin LSP client
-- lsp_type_definitions: type definitions of the word under the cursor from the builtin LSP client
-- quickfix: quickfix items
-- loclist: items from the window's location list

-- NOTE: Also figure out how to do lower inline hint(maybe not needed after nvim v0.10)
-- trouble.open_with_trouble(mode?)
-- -- toggle trouble with optional mode
-- require("trouble").toggle(mode?)
--
-- -- open trouble with optional mode
-- require("trouble").open(mode?)
--
-- -- close trouble
-- require("trouble").close()
--
-- -- jump to the next item, skipping the groups
-- require("trouble").next({skip_groups = true, jump = true});
--
-- -- jump to the previous item, skipping the groups
-- require("trouble").previous({skip_groups = true, jump = true});
--
-- -- jump to the first item, skipping the groups
-- require("trouble").first({skip_groups = true, jump = true});
--
-- -- jump to the last item, skipping the groups
-- require("trouble").last({skip_groups = true, jump = true});
