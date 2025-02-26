#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = "tmp"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    -- "LazyVim/starter",
    -- "williamboman/mason-lspconfig.nvim",
    -- "williamboman/mason.nvim",
    -- "nvim-treesitter/nvim-treesitter",
    {
      dir = "~/Github/async.nvim",
      config = function()
        async_it = require("async.test").async_it
        Callback = require("callback")
        Promise = require("promise")
        Timers = require("timers")
        await = Promise.await
        p = function(...)
          return vim.print(vim.inspect(...))
        end
      end,
    },
    -- "izelnakri/async.nvim",
    -- NOTE: add async.test require here
  },
})
