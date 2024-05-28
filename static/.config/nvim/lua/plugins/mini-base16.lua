local function read_system_colors(system_color_path)
  local json_file = io.open(system_color_path, "r")
  if json_file == nil then
    print("Failed to open JSON file")
    return
  end
  local json_content = json_file:read("*all")
  json_file:close()
  return vim.json.decode(json_content)
end

return {
  {
    "echasnovski/mini.base16",
    config = function()
      local lib = require("mini.base16")
      -- TODO: make this palette read from a json or yaml from the file system
      local color_palette = read_system_colors(vim.fn.expand("$HOME/.config/system-colors.json"))

      local palette = {
        base00 = "#" .. color_palette["base00"],
        base01 = "#" .. color_palette["base01"],
        base02 = "#" .. color_palette["base02"],
        base03 = "#" .. color_palette["base03"],
        base04 = "#" .. color_palette["base04"],
        base05 = "#" .. color_palette["base05"],
        base06 = "#" .. color_palette["base06"],
        base07 = "#" .. color_palette["base07"],
        base08 = "#" .. color_palette["base08"],
        base09 = "#" .. color_palette["base09"],
        base0A = "#" .. color_palette["base0A"],
        base0B = "#" .. color_palette["base0B"],
        base0C = "#" .. color_palette["base0C"],
        base0D = "#" .. color_palette["base0D"],
        base0E = "#" .. color_palette["base0E"],
        base0F = "#" .. color_palette["base0F"],
      }
      local hi = function(group, args)
        local command
        if args.link ~= nil then
          command = string.format("highlight! link %s %s", group, args.link)
        else
          command = string.format(
            "highlight %s guifg=%s guibg=%s gui=%s guisp=%s",
            group,
            args.fg or "NONE",
            args.bg or "NONE",
            args.attr or "NONE",
            args.sp or "NONE"
          )
        end
        vim.cmd(command)
      end

      lib.setup({
        palette = palette,
      })

      hi("@lsp.type.variable", { fg = palette.base0D })
      hi("@variable", { fg = palette.base0D })
      hi("@function.method.call", { fg = palette.base09 })
      hi("Boolean", { fg = palette.base0C })
      hi("Comment", { fg = palette.base0F })
      hi("Delimiter", { fg = palette.base06 })
      hi("Function", { fg = palette.base09 })
      hi("Identifier", { fg = palette.base0D })
      hi("Keyword", { fg = palette.base08 })
      hi("Number", { fg = palette.base0C })
      hi("Macro", { fg = palette.base09 })
      hi("SpecialChar", { fg = palette.base09 })
      hi("String", { fg = palette.base0A })
      hi("Structure", { fg = palette.base0C })
      hi("Type", { fg = palette.base09 })
      hi("Tag", { fg = palette.base0D })

      hi("@markup.heading", { fg = palette.base0E, attr = "bold" })
      hi("@markup.link.label", { fg = palette.base0D, attr = "underline" })
      hi("@markup.link.url", { fg = palette.base0C })
      hi("@markup.list", { fg = palette.base09 })
      hi("@markup.raw", { fg = palette.base06, attr = "bold" })
      hi("@markup.strong", { fg = palette.base03, attr = "bold" })

      hi("DiffChange", { fg = palette.base09, bg = palette.base01 })
      hi("NeoTreeGitModified", { fg = palette.base09 })
      hi("diffChanged", { fg = palette.base09 })
      hi("Changed", { fg = palette.base09 })
      hi("gitcommitHeader", { fg = palette.base09 })

      hi("DiagnosticWarn", { fg = palette.base09 })
      hi("DiagnosticFloatingWarn", { fg = palette.base09, bg = palette.base01 })
      hi("DiagnosticUnderlineWarn", { fg = nil, attr = "underline", sp = palette.base09 })
      hi("NoiceConfirmBorder", { fg = palette.base09 })

      hi("NotifyWARNBorder", { fg = palette.base09 })
      hi("NotifyWARNIcon", { fg = palette.base09 })
      hi("NotifyWARNTitle", { fg = palette.base09 })

      hi("WhichKeyGroup", { fg = palette.base09 })
      hi("GitSignsChange", { fg = palette.base09, bg = palette.base01 })
      hi("NeoTreeGitUntracked", { fg = palette.base0F })

      hi("LineNr", { fg = palette.base03 })
      hi("WinSeparator", { fg = palette.base02 })
      hi("WinBar", { fg = palette.base04 })
      hi("WinBarNC", { fg = palette.base04 })
      -- NOTE: This is the background of K:hover, only add a border
      hi("NormalFloat", { fg = palette.base05 }) -- NOTE: Maybe make bg base00
      hi("FloatBorder", { fg = palette.base05, bg = palette.base01 }) -- NOTE: Maybe make bg base00

      -- Maybe in future change: BufferInactiveTarget, BufferVisible, BufferVisibleTarget, BufferVisibleMod

      hi("MiniMapSymbolLine", { fg = palette.base08 })

      hi("GitSignsUntracked", { fg = palette.base0F, bg = palette.base01 })

      -- hi("ColorColumn", { fg = nil })
      -- ColorColumnxxx cterm=reverse guibg=#0c241e

      -- Maybe in future change:
      -- DiagnosticFloatingErrorxxx guifg=#ef5d32 guibg=#0c241e
      -- DiagnosticErrorxxx ctermfg=9 guifg=#ef5d32
      -- DiagnosticFloatingWarnxxx guifg=#efaa32 guibg=#0c241e
      -- DiagnosticWarnxxx ctermfg=11 guifg=#efaa32
      -- DiagnosticFloatingInfoxxx guifg=#7daf9c guibg=#0c241e
      -- DiagnosticInfoxxx ctermfg=14 guifg=#7daf9c
      -- DiagnosticFloatingHintxxx guifg=#85b1dd guibg=#0c241e
      -- DiagnosticHintxxx ctermfg=12 guifg=#85b1dd
      -- DiagnosticFloatingOkxxx guifg=#3a9d4b guibg=#0c241e
    end,
  },
}

-- local palette = {
-- # base00: "#020f0c" # | ---: Selection Background -- dark green/black [needs to change]
-- # base01: "#0c241e" # | Default background, dark -- dark green/black
-- # base02: "#0d372d" # | Lighter Background (Used for status bars) -- slightly lighter shade of dark green/black
-- # base03: "#5E6E5E" # | Comments, Invisibles, Line Highlighting -- a muted greenish-gray for better readability, maybe this needs to be lighter for markdown strong tag styling
-- # base04: "#485848" # | +: Dark Foreground (Used for status bars) -- darker shade for contrast with light text
-- # TODO: This has to be brighter!!:
-- # base05: "#D6E3C6" # | ++: Default Foreground, Caret, Delimiters, Operators -- light gray for primary text
-- # base06: "#E3EFE1" # | +++: Light Foreground (Not often used) -- even lighter gray for secondary text
-- # base07: "#F5F9F5" # | ++++: The Lightest Foreground (Not often used) -- very light gray for background
-- # base08: "#EF5D32" # | red: Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted -- bright red for emphasis
-- # base09: "#EFAA32" # | orange: Integers, Boolean, Constants, XML Attributes, Markup Link Url -- warm orange for visibility
-- # base0A: "#FFD580" # | yellow: Classes, Markup Bold, Search Text Background -- softer yellow for less strain
-- # base0B: "#3a9d4b" # | green: Strings, Inherited Class, Markup Code, Diff Inserted -- vibrant green for clarity
-- # base0C: "#7DAF9C" # | cyan: Support, Regular Expressions, Escape Characters, Markup Quotes -- soothing cyan for contrast
-- # base0D: "#85B1DD" # | blue: Functions, Methods, Attribute IDs, Headings -- calm blue for readability
-- # base0E: "#B389D6" # | purple: Keywords, Storage, Selector, Markup Italic, Diff Changed -- rich purple for distinction
-- # base0F: "#A87C50" # | brown: Deprecated Highlighting for Methods and Functions, Opening/Closing Embedded Language Tags -- earthy brown for deprecated elements
-- # base10: "#666666" # | darker_black: Darker Background -- slightly darker shade of dark green/black
-- # base11: "#333333" # | darkest_black: The Darkest Background -- black
-- # base12: "#FF3333" # | bright_red: Error, Tag Matching, Non-Captured Groups -- bright red for critical elements
-- # base13: "#FFFF00" # | bright_yellow: Debugging, Regex Quantifiers, Escape Characters -- bright yellow for attention
-- # base14: "#4CFF00" # | bright_green: Diff Changed, Operators, Punctuation -- vibrant green for visibility
-- # base15: "#00FFFF" # | bright_cyan: Diff Inserted, Diff Inserted Indicator, Markup Quotes -- cyan for contrast
-- # base16: "#0066FF" # | bright_blue: Diff Header, Markup Underline, Diff Changed Indicator -- bright blue for differentiation
-- # base17: "#FF00FF" # | bright_purple: Diff Deleted, Markup Strike-through, Special Keyword -- bright purple for emphasis
-- }
