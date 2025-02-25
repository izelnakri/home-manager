-- Learn vimwiki
-- TODO: Create git integration(open lazygit with this context)
-- Search and search file also needs to have vimwiki context!
-- Vimwiki needs to be markdown
-- integrate it with taskwarrior
-- integrate it with calendar
-- tags nvim plugin: <leader>T Rg :python: -> opens in quickfix buffer, also telescope. ALSO: each folder creates its tag for all its files
-- watch neorg videos

--
-- TODO: diary template, note template, better <leader>now, : https://youtu.be/9Bb8Ljyqpt4?si=Icoa1MsZymCTgAOZ&t=1110
return {
  {
    "vimwiki/vimwiki",
    keys = {
      { "<leader>ww", "<Plug>VimwikiIndex", desc = "Other Window", remap = true },
      {
        "<leader>now",
        function()
          local date = os.date("%A, %F | %T %Z")
          return vim.cmd('r ! echo "**' .. date .. '**"')
        end,
      },
    },
  },
}
