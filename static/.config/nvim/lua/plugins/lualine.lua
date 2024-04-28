return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_c[4] = { "filename", path = 1 }
    opts.sections.lualine_c[5] = { "" } -- something adds in lualine_c[6] in an advanced but ugly way so we keep that one, 5th is redundant
    opts.sections.lualine_z = {}
  end,
}
