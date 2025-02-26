local M = {}

M.test_file_lookup_by_ft = {
  ruby = "",
  javascript = "",
  typescript = "",
  elixir = "",
  gleam = "",
  lua = "",
  rust = "",
}

M.test_command_lookup_by_fy = {
  ruby = [],
  javascript = [],
  typescript = [],
  elixir = [],
  gleam = [],
  lua = [],
  rust = [],
}

-- NOTE: Find test directory
function M.dirname(path) end

-- NOTE: find the possible test path
function M.test_file(path) end

-- NOTE: find the possible test path
function M.run_test(path) end
--
-- NOTE: find the possible test path
function M.run_tests(paths) end

return {}

-- for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
--   if vim.fn.isdirectory(dir .. "/.git") == 1 then
--     root_dir = dir
--     break
--   end
-- end
