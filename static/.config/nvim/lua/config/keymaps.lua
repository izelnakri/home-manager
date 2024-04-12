-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Replace on highlighted areas:
vim.cmd("nnoremap <Leader>r :%s///gc<left><left><left>")

-- TODO: check if there is a keybinding for go to breakpoints, show a list of breakpoints, better test outputs in the editor

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
