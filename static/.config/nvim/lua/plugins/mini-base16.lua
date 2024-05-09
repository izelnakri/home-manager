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

      hi("@lsp.type.variable", { fg = palette.base0D, bg = nil, attr = nil, sp = nil })
      hi("@variable", { fg = palette.base0D, bg = nil, attr = nil, sp = nil })
      hi("@function.method.call", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("Boolean", { fg = palette.base0C, bg = nil, attr = nil, sp = nil })
      hi("Comment", { fg = palette.base0F, bg = nil, attr = nil, sp = nil })
      hi("Delimiter", { fg = palette.base06, bg = nil, attr = nil, sp = nil })
      hi("Function", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("Identifier", { fg = palette.base0D, bg = nil, attr = nil, sp = nil })
      hi("Keyword", { fg = palette.base08, bg = nil, attr = nil, sp = nil })
      hi("Number", { fg = palette.base0C, bg = nil, attr = nil, sp = nil })
      hi("Macro", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("SpecialChar", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("String", { fg = palette.base0A, bg = nil, attr = nil, sp = nil })
      hi("Structure", { fg = palette.base0C, bg = nil, attr = nil, sp = nil })
      hi("Type", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("Tag", { fg = palette.base0D, bg = nil, attr = nil, sp = nil })

      hi("@markup.heading", { fg = palette.base0E, bg = nil, attr = "bold", sp = nil })
      hi("@markup.link.label", { fg = palette.base0D, bg = nil, attr = "underline", sp = nil })
      hi("@markup.link.url", { fg = palette.base0C, bg = nil, attr = nil, sp = nil })
      hi("@markup.list", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("@markup.raw", { fg = palette.base06, bg = nil, attr = "bold", sp = nil })
      hi("@markup.strong", { fg = palette.base03, bg = nil, attr = "bold", sp = nil })

      hi("DiffChange", { fg = palette.base09, bg = palette.base01, attr = nil, sp = nil })
      hi("NeoTreeGitModified", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("diffChanged", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("Changed", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("gitcommitHeader", { fg = palette.base09, bg = nil, attr = nil, sp = nil })

      hi("DiagnosticWarn", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("DiagnosticFloatingWarn", { fg = palette.base09, bg = palette.base01, attr = nil, sp = nil })
      hi("DiagnosticUnderlineWarn", { fg = nil, bg = nil, attr = "underline", sp = palette.base09 })
      hi("NoiceConfirmBorder", { fg = palette.base09, bg = nil, attr = nil, sp = nil })

      hi("NotifyWARNBorder", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("NotifyWARNIcon", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("NotifyWARNTitle", { fg = palette.base09, bg = nil, attr = nil, sp = nil })

      hi("WhichKeyGroup", { fg = palette.base09, bg = nil, attr = nil, sp = nil })
      hi("GitSignsChange", { fg = palette.base09, bg = palette.base01, attr = nil, sp = nil })
      hi("NeoTreeGitUntracked", { fg = palette.base0F, bg = nil, attr = nil, sp = nil })
    end,
  },
}

-- local palette = {
--   base00 = "#09251f",
--   base01 = "#0d372d",
--   base02 = "#101818",
--   base03 = "#5E6E5E",
--   base04 = "#485848",
--   base05 = "#D6E3C6",
--   base06 = "#E3EFE1",
--   base07 = "#F5F9F5",
--   base08 = "#EF5D32",
--   base09 = "#EFAA32",
--   base0A = "#FFD580",
--   base0B = "#BDD93A",
--   base0C = "#9ED795",
--   base0D = "#85B1DD",
--   base0E = "#7B68EE", -- NOTE: always assumes this is the orange color
--   base0F = "#A87C50",
-- }
