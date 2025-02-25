-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set

-- vim.on_key(function(a, b, c)
--   print(vim.inspect(a), vim.inspect(b), vim.inspect(c))
-- end)

-- NOTE: I can also map by decimal shown in $ showkey -a:
-- vim.keymap.set({ "n", "i" }, "<Char-94>", function()
--   Utils.notify("Key with 94 decimal charcode called")
-- end)

-- Replace on highlighted areas:
vim.cmd("nnoremap <Leader>r :%s///gc<left><left><left>")

-- Vertical & horizontal sizing:
keymap("n", "<M-,>", "<C-w>5>")
keymap("n", "<M-.>", "<C-w>5<")
keymap("n", "<M-=>", "<C-w>+", { remap = true })
keymap("n", "<M-->", "<C-w>-", { remap = true })

keymap("n", "<leader>hm", function()
  vim.print("Home manager file command!")
end)
keymap("n", "<leader>hs", function()
  vim.print("SEARCH- home manager called!")
  -- require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
end)
keymap("n", "<leader>ur", function()
  vim.print("anana called!")
  vim.cmd([[so %]])
end)

-- -- Easily hit escape in terminal mode:
-- keymap("t", "<Esc><Esc>", "<C-\\><C-n>")
--
-- -- Fixed-height Bottom terminal:
-- keymap("n", ",st", function()
--   vim.cmd.new()
--   vim.cmd.windcmd("J")
--   vim.api.nvim_win_set_height(0, 12)
--   vim.wo.winfixheight = true
--   vim.cmd.term()
-- end)

-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
-- vim.keymap.set("n", "<leader><leader>", function()
--     vim.cmd("so")
-- end)
--
-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz") -- NOTE: go down in diagnostic errors
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz") -- NOTE: go up in diagnostic errors
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz") -- NOTE: go down in location list
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz") -- NOTE: go up in location list

-- vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
-- vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
-- vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
-- vim.keymap.set("n", "<leader>tc", function()
--     neotest.run.run()
-- end)

-- NOTE: Does this even work?
vim.cmd([[
:map <esc>[1;5D <C-Left>
:map <esc>[1;5C <C-Right>
]])

-- `:bnext` & `:bprev`

vim.keymap.set("n", "<C-Right>", function()
  LazyVim.notify("HELLO")
end, { desc = "Print hello" })

-- vim.lsp.handlers["textDocument/hover"](nil, "textDocument/hover", {
--   contents = {
--     "this is hovered text",
--     "it works exactly the way users want!",
--   },
-- })

-- TODO: check if there is a keybinding for go to breakpoints, show a list of breakpoints, better test outputs in the editor

-- greatest remap ever
-- vim.keymap.set("x", "<leader>p", [["_dP]])

-- map <Leader>mg :Magit<CR>

-- function! ReadSnippet(snippetName)
--   return readfile($HOME . "/.config/nvim/snippets/" . a:snippetName)
-- endfunction
--
-- command! ConfigMap :call setbufline("", line("."), ReadSnippet("ConfigMap.yaml"))
-- command! CronJob :call setbufline("", line("."), ReadSnippet("CronJob.yaml"))
-- command! Deployment :call setbufline("", line("."), ReadSnippet("Deployment.yaml"))
-- command! HorizontalPodAutoscaler :call setbufline("", line("."), ReadSnippet("HorizontalPodAutoscaler.yaml"))
-- command! Ingress :call setbufline("", line("."), ReadSnippet("Ingress.yaml"))
-- command! Job :call setbufline("", line("."), ReadSnippet("Job.yaml"))
-- command! PersistentVolume :call setbufline("", line("."), ReadSnippet("PersistentVolume.yaml"))
-- command! PersistentVolumeClaim :call setbufline("", line("."), ReadSnippet("PersistentVolumeClaim.yaml"))
-- command! Role :call setbufline("", line("."), ReadSnippet("Role.yaml"))
-- command! RoleBinding :call setbufline("", line("."), ReadSnippet("RoleBinding.yaml"))
-- command! Service :call setbufline("", line("."), ReadSnippet("Service.yaml"))
-- command! ServiceAccount :call setbufline("", line("."), ReadSnippet("ServiceAccount.yaml"))
-- command! StatefulSet :call setbufline("", line("."), ReadSnippet("StatefulSet.yaml"))

-- TODO:
-- Expand Macros:
-- :RustLsp expandMacro
-- vim.cmd.RustLsp('expandMacro')
--
-- Render Diagnostics:
-- :RustLsp renderDiagnostics
-- vim.cmd.RustLsp('renderDiagnostic')
--
-- joinLines:
-- :RustLsp joinLines
-- vim.cmd.RustLsp('joinLines')
--
-- Generate dep graphs:
-- :RustLsp crateGraph {backend {output}}
-- vim.cmd.RustLsp { 'crateGraph', '[backend]', '[output]' }
--
-- Show module dap support, check if in JS it already works, also testing
--
-- Documentation open in browser(with context from the tool)[
-- possible for cargo,
-- not possible for stdlib in JS(but maybe put it in devdocs),
-- not possible for stdlib in Elixir(but put it in devdocs),
-- check local docs generation from deno documentation for custom types
-- check local docs generation for elixir for custom types
-- ]
-- Meanwhile use K -> and build initial version for cargo docs
--
-- " TODO: Test bindings, does these even work?!
-- nmap <silent> t<C-n> :TestNearest<CR>
-- nmap <silent> t<C-f> :TestFile<CR>
-- nmap <silent> t<C-s> :TestSuite<CR>
-- nmap <silent> t<C-l> :TestLast<CR>
-- nmap <silent> t<C-g> :TestVisit<CR>
-- map <Leader>r :reg<CR>
--
--
--
--
--

-- To make keymaps per filetype:
-- autocmd("BufWinEnter", {
--     group = ThePrimeagen_Fugitive,
--     pattern = "*.rb", -- NOTE: can also be an array
--     callback = function()
--         if vim.bo.ft ~= "fugitive" then
--             return
--         end
--
--         local bufnr = vim.api.nvim_get_current_buf()
--         local opts = {buffer = bufnr, remap = false}
--         vim.keymap.set("n", "<leader>p", function()
--             vim.cmd.Git('push')
--         end, opts)
--
--         -- rebase always
--         vim.keymap.set("n", "<leader>P", function()
--             vim.cmd.Git({'pull',  '--rebase'})
--         end, opts)
--
--         -- NOTE: It allows me to easily set the branch i am pushing and any tracking
--         -- needed if i did not set the branch up correctly
--         vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts);
--     end,
-- })

-- map <silent> <M-a> gg<S-v>G
