-- vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
--   desc = "Custom: Open help buffers in splits",
--   pattern = "*.txt",
--   callback = function()
--     if vim.bo.filetype == "help" then
--       vim.cmd("wincmd L")
--     end
--   end,
-- })

-- • buffer (integer) optional: buffer number for buffer-local
--   autocommands |autocmd-buflocal|. Cannot be used with
--   {pattern}.
-- • pattern (string|array) optional: pattern(s) to match
--   literally |autocmd-pattern|.
-- • group: (number|nil) autocommand group id, if any
-- • match: (string) expanded value of <amatch>
-- • buf: (number) expanded value of <abuf>
-- • file: (string) expanded value of <afile>
-- • data: (any) arbitrary data passed from
--   |nvim_exec_autocmds()|                       *event-data*

vim.wo.number = true

-- vim.bo.tw = 120 -- Then gq on selected text makes it formatted, but it doesnt take into account language semantics
--
-- autocmd BufWinEnter <buffer> wincmd L
