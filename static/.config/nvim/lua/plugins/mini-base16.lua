return {
  {
    "echasnovski/mini.base16",
    config = function()
      require("mini.base16").setup({
        -- TODO: make this palette read from a json or yaml from the file system
        palette = {
          base00 = "#09251f",
          base01 = "#0d372d",
          base02 = "#101818",
          base03 = "#5E6E5E",
          base04 = "#485848",
          base05 = "#D6E3C6",
          base06 = "#E3EFE1",
          base07 = "#F5F9F5",
          base08 = "#EF5D32",
          base09 = "#EFAA32",
          base0A = "#FFD580",
          base0B = "#BDD93A",
          base0C = "#9ED795",
          base0D = "#85B1DD",
          base0E = "#7B68EE",
          base0F = "#A87C50",
        },
      })
    end,
  },
}

-- p, hi = H.make_compound_palette(palette, use_cterm), H.highlight_both
-- hi('Character',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('Comment',        {fg=p.base03, bg=nil,      attr=nil, sp=nil})
-- hi('Conditional',    {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
-- hi('constant',       {fg=p.base09, bg=nil,      attr=nil, sp=nil})
-- hi('debug',          {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('define',         {fg=p.base0e, bg=nil,      attr=nil, sp=nil})
-- hi('delimiter',      {fg=p.base0f, bg=nil,      attr=nil, sp=nil})
-- hi('error',          {fg=p.base00, bg=p.base08, attr=nil, sp=nil})
-- hi('Exception',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('Float',          {fg=p.base09, bg=nil,      attr=nil, sp=nil})
-- hi('Function',       {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
-- hi('Identifier',     {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('Ignore',         {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
-- hi('Include',        {fg=p.base0D, bg=nil,      attr=nil, sp=nil})
-- hi('Keyword',        {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
-- hi('Label',          {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('Macro',          {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('Number',         {fg=p.base09, bg=nil,      attr=nil, sp=nil})
-- hi('Operator',       {fg=p.base05, bg=nil,      attr=nil, sp=nil})
-- hi('PreCondit',      {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('PreProc',        {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('Repeat',         {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('Special',        {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
-- hi('SpecialChar',    {fg=p.base0F, bg=nil,      attr=nil, sp=nil})
-- hi('SpecialComment', {fg=p.base0C, bg=nil,      attr=nil, sp=nil})
-- hi('Statement',      {fg=p.base08, bg=nil,      attr=nil, sp=nil})
-- hi('StorageClass',   {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('String',         {fg=p.base0B, bg=nil,      attr=nil, sp=nil})
-- hi('Structure',      {fg=p.base0E, bg=nil,      attr=nil, sp=nil})
-- hi('Tag',            {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('Todo',           {fg=p.base0A, bg=p.base01, attr=nil, sp=nil})
-- hi('Type',           {fg=p.base0A, bg=nil,      attr=nil, sp=nil})
-- hi('Typedef',        {fg=p.base0A, bg=nil,      attr=nil, sp=nil})

-- hi('NeoTreeDimText',              {fg=p.base03, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeDotfile',              {fg=p.base04, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeFadeText1',            {link='NeoTreeDimText'})
-- hi('NeoTreeFadeText2',            {fg=p.base02, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeGitAdded',             {fg=p.base0B, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeGitConflict',          {fg=p.base08, bg=nil,      attr='bold', sp=nil})
-- hi('NeoTreeGitDeleted',           {fg=p.base08, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeGitModified',          {fg=p.base0E, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeGitUnstaged',          {fg=p.base08, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeGitUntracked',         {fg=p.base0A, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeMessage',              {fg=p.base05, bg=p.base01, attr=nil,    sp=nil})
-- hi('NeoTreeModified',             {fg=p.base07, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeRootName',             {fg=p.base0D, bg=nil,      attr='bold', sp=nil})
-- hi('NeoTreeTabInactive',          {fg=p.base04, bg=nil,      attr=nil,    sp=nil})
-- hi('NeoTreeTabSeparatorActive',   {fg=p.base03, bg=p.base02, attr=nil,    sp=nil})
-- hi('NeoTreeTabSeparatorInactive', {fg=p.base01, bg=p.base01, attr=nil,    sp=nil})
