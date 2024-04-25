vim.cmd([[
  function! OpenMarkdownBrowserOnTheRight(url)
    let active_window = system('hyprctl -j activeworkspace | jq .id')

    execute '!brave ' . a:url
    execute '!hyprctl dispatch movetoworkspacesilent ' . substitute(active_window, '\n', '', 'g') . ',title:Brave'
    execute '!hyprctl dispatch swapwindow r'
  endfunction
]])

return {
  {
    "iamcco/markdown-preview.nvim",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
    },
    event = "BufRead",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    opts = function()
      vim.g.mkdp_auto_start = 1
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_browserfunc = "OpenMarkdownBrowserOnTheRight"
    end,
  },
}
