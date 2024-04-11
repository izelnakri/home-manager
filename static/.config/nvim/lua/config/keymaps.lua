-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Replace on highlighted areas:
vim.cmd("nnoremap <Leader>r :%s///gc<left><left><left>")

-- map <Leader>mg :Magit<CR>

-- Learn Keymaps for: Surround, Project file/replace,
-- nmap <silent> t<C-n> :TestNearest<CR>
-- nmap <silent> t<C-f> :TestFile<CR>
-- nmap <silent> t<C-s> :TestSuite<CR>
-- nmap <silent> t<C-l> :TestLast<CR>
-- nmap <silent> t<C-g> :TestVisit<CR>

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

-- TODO: Implement LSP motions
--
