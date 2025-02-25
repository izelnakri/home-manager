-- TODO: implement watch for qunitx like jest: "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>"
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "haydenmeade/neotest-jest",
      "marilari88/neotest-vitest",
      -- "MarkEmmons/neotest-deno",
    },
    -- keys = {
    --   {
    --     "<leader>tw",
    --     "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
    --     desc = "Run Watch",
    --   },
    -- },
    opts = function(_, opts)
      table.insert(
        opts.adapters,
        require("neotest-jest")({
          jestCommand = "npm test --",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        })
      )
      table.insert(opts.adapters, require("neotest-vitest"))
      -- table.insert(opts.adapters, require("neotest-deno"))
    end,
  },
}
