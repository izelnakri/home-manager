require("izelnakri.utils.buffer")
require("izelnakri.utils.cmd_line")
require("izelnakri.utils.cursor")
require("izelnakri.utils.cursor_selection")
require("izelnakri.utils.fs")
require("izelnakri.utils.list")
require("izelnakri.utils.object")
require("izelnakri.utils.option")
require("izelnakri.utils.string")
require("izelnakri.utils.system")
require("izelnakri.utils.tab_page")
require("izelnakri.utils.terminal")
require("izelnakri.utils.ui")
require("izelnakri.utils.window")
require("izelnakri.utils.window_view")

-- TODO: Maybe run lua with types maybe instead of doc comments?

Utils = {}

--- @return string : Returns vim.bo.filetype
function Utils.get_filetype()
  return vim.bo.filetype
end

function Utils.notify(msg, level, opts)
  vim.notify = require("notify")

  if msg == nil or msg == "" then
    return vim.notify("nil")
  end

  return vim.notify(vim.inspect(msg), level, opts)
end

--- @class Base16SystemPalette
--- @field base00 string
--- @field base01 string
--- @field base02 string
--- @field base03 string
--- @field base04 string
--- @field base05 string
--- @field base06 string
--- @field base07 string
--- @field base08 string
--- @field base09 string
--- @field base0A string
--- @field base0B string
--- @field base0C string
--- @field base0D string
--- @field base0E string
--- @field base0F string

--- @param system_color_path string
--- @return Base16SystemPalette? : Lua table that is converted from your $system_color_path
function Utils.read_system_colors(system_color_path)
  local json_file = io.open(system_color_path, "r")
  if json_file == nil then
    print("Failed to open JSON file")
    return
  end
  local json_content = json_file:read("*all")
  json_file:close()

  return vim.json.decode(json_content)
end

return Utils

-- NOTE: From previous notes:
--
-- nvim_buf_get_text({buffer}, {start_row}, {start_col}, {end_row}, {end_col},
--                   {opts})

-- vim.ui.input({ prompt = "Enter value for this: " }, function(input)
--   vim.print("input is " .. input)
-- end)

-- vim.ui.select({ "tabs", "spaces" }, {
--   prompt = "Select tabs or spaces:",
--   format_item = function(item)
--  nvim_get_visual_selection   return "I'd like to choose " .. item
--   end,
-- }, function(choice)
--   vim.print("choice is " .. choice)
-- end)
--
-- local bufnr = vim.api.nvim_create_buf(false, true) -- or 1164 (nvim_get_current_buf())
-- vim.api.nvim_buf_attach(0, false, {
--  on_lines = function(_, _, _, first_line, last_line)
--    local lines = vim.api.nvim_buf_get_lines(0, first_line, last_line, false)
--    -- NOTE: or do vim.schedule here only
--    vim.schedule(function() vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines) end)
--  end
--})

-- getcmdline()                                                      *getcmdline()*
-- 		Return the current command-line.  Only works when the command
-- 		line is being edited, thus requires use of |c_CTRL-\_e| or
-- 		|c_CTRL-R_=|.
-- 		Example: >vim
-- 			cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR>
-- <		Also see |getcmdtype()|, |getcmdpos()|, |setcmdpos()| and
-- 		|setcmdline()|.
-- 		Returns an empty string when entering a password or using
-- 		|inputsecret()|.

-- TODO: Read on 'virtualedit'

-- CMD
-- histnr({history})                                                     *histnr()*
-- 		The result is the Number of the current entry in {history}.
-- 		See |hist-names| for the possible values of {history}.
-- 		If an error occurred, -1 is returned.
--
-- 		Example: >vim
-- 			let inp_index = histnr("expr")
--
-- histget({history} [, {index}])                                       *histget()*
-- 		The result is a String, the entry with Number {index} from
-- 		{history}.  See |hist-names| for the possible values of
-- 		{history}, and |:history-indexing| for {index}.  If there is
-- 		no such entry, an empty String is returned.  When {index} is
-- 		omitted, the most recent item from the history is used.
--
-- 		Examples:
-- 		Redo the second last search from history. >vim
-- 			execute '/' .. histget("search", -2)
--
-- <		Define an Ex command ":H {num}" that supports re-execution of
-- 		the {num}th entry from the output of |:history|. >vim
-- 			command -nargs=1 H execute histget("cmd", 0+<args>)

-- NOTE:
-- undotree([{buf}])                                                   *undotree()*
-- 		Return the current state of the undo tree for the current
-- 		buffer, or for a specific buffer if {buf} is given.  The
-- 		result is a dictionary with the following items:
-- 		  "seq_last"	The highest undo sequence number used.
-- 		  "seq_cur"	The sequence number of the current position in
-- 				the undo tree.  This differs from "seq_last"
-- 				when some changes were undone.
-- 		  "time_cur"	Time last used for |:earlier| and related
-- 				commands.  Use |strftime()| to convert to
-- 				something readable.
-- 		  "save_last"	Number of the last file write.  Zero when no
-- 				write yet.
-- 		  "save_cur"	Number of the current position in the undo
-- 				tree.
-- 		  "synced"	Non-zero when the last undo block was synced.
-- 				This happens when waiting from input from the
-- 				user.  See |undo-blocks|.
-- 		  "entries"	A list of dictionaries with information about
-- 				undo blocks.
--
-- 		The first item in the "entries" list is the oldest undo item.
-- 		Each List item is a |Dictionary| with these items:
-- 		  "seq"		Undo sequence number.  Same as what appears in
-- 				|:undolist|.
-- 		  "time"	Timestamp when the change happened.  Use
-- 				|strftime()| to convert to something readable.
-- 		  "newhead"	Only appears in the item that is the last one
-- 				that was added.  This marks the last change
-- 				and where further changes will be added.
-- 		  "curhead"	Only appears in the item that is the last one
-- 				that was undone.  This marks the current
-- 				position in the undo tree, the block that will
-- 				be used by a redo command.  When nothing was
-- 				undone after the last change this item will
-- 				not appear anywhere.
-- 		  "save"	Only appears on the last block before a file
-- 				write.  The number is the write count.  The
-- 				first write has number 1, the last one the
-- 				"save_last" mentioned above.
-- 		  "alt"		Alternate entry.  This is again a List of undo
-- 				blocks.  Each item may again have an "alt"
-- 				item.

-- mode() -> to change mode?

-- vim.tbl_filter(M.is_valid, vim.api.nvim_list_bufs())
--   vim.tbl_map(function(item) return item.id end, elements)

-- NOTE: There is loclist, qflist, arglist(?) - file navigation, jumplist, clist(error list(?))
