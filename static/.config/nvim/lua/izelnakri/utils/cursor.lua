-- NOTE: line() and line('.', {winid}) for cursor position

--- @class Cursor
--- @field screenrow integer
--- @field screencol integer
--- @field winid integer
--- @field winrow integer
--- @field wincol integer
--- @field line integer
--- @field column integer

--- @class vim.fn.winsaveview.ret: vim.fn.winrestview.dict --> Essentially gets the cursor information. NOTE: Where does the other buf cols stored?!
--- @field col integer
--- @field coladd integer
--- @field curswant integer
--- @field leftcol integer
--- @field lnum integer
--- @field skipcol integer
--- @field topfill integer
--- @field topline integer --> This is the top row of the "viewed"

Cursor = {}

-- NOTE: return window view association(?)
-- winid
function Cursor:peek(winid)
  if winind == nil then
    -- local winid =
    local cursor = vim.api.nvim_win_get_cursor(0) -- Correct absolute

    return {
      -- winid =
      winrow = cursor[1],
      wincol = cursor[2],
    }
  end
end

-- nvim_win_set_cursor({window}, {pos})                   *nvim_win_set_cursor()*
--     Sets the (1,0)-indexed cursor position in the window. |api-indexing| This
--     scrolls the window even if it is not the current one.
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {pos}     (row, col) tuple representing the new position

-- nvim_win_get_cursor({window})                          *nvim_win_get_cursor()*
--     Gets the (1,0)-indexed, buffer-relative cursor position for a given window
--     (different windows showing the same buffer have independent cursor
--     positions). |api-indexing|
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         (row, col) tuple
--
--     See also: ~
--       • |getcurpos()|

-- nvim_set_current_line({line})                        *nvim_set_current_line()*
--     Sets the current line.
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {line}  Line contents

-- nvim_paste({data}, {crlf}, {phase})                             *nvim_paste()*
--     Pastes at cursor, in any mode.
--
--     Invokes the `vim.paste` handler, which handles each mode appropriately.
--     Sets redo/undo. Faster than |nvim_input()|. Lines break at LF ("\n").
--
--     Errors ('nomodifiable', `vim.paste()` failure, …) are reflected in `err`
--     but do not affect the return value (which is strictly decided by
--     `vim.paste()`). On error, subsequent calls are ignored ("drained") until
--     the next paste is initiated (phase 1 or -1).
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {data}   Multiline input. May be binary (containing NUL bytes).
--       • {crlf}   Also break lines at CR and CRLF.
--       • {phase}  -1: paste in a single call (i.e. without streaming). To
--                  "stream" a paste, call `nvim_paste` sequentially with these
--                  `phase` values:
--                  • 1: starts the paste (exactly once)
--                  • 2: continues the paste (zero or more times)
--                  • 3: ends the paste (exactly once)
--
--     Return: ~
--         • true: Client may continue pasting.
--         • false: Client must cancel the paste.
--
-- nvim_put({lines}, {type}, {after}, {follow})                      *nvim_put()*
--     Puts text at cursor, in any mode.
--
--     Compare |:put| and |p| which are always linewise.
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {lines}   |readfile()|-style list of lines. |channel-lines|
--       • {type}    Edit behavior: any |getregtype()| result, or:
--                   • "b" |blockwise-visual| mode (may include width, e.g. "b3")
--                   • "c" |charwise| mode
--                   • "l" |linewise| mode
--                   • "" guess by contents, see |setreg()|
--       • {after}   If true insert after cursor (like |p|), or before (like
--                   |P|).
--       • {follow}  If true place cursor at end of inserted text.

-- function Cursor.change(winid)
-- -- vim.fn.cursor({lnum}, {col} [, {off}])                                       *cursor()*
-- -- cursor({list})
-- -- 		Positions the cursor at the column (byte count) {col} in the
-- -- 		line {lnum}.  The first column is one.
-- --
-- -- 		When there is one argument {list} this is used as a |List|
-- -- 		with two, three or four item:
-- -- 			[{lnum}, {col}]
-- -- 			[{lnum}, {col}, {off}]
-- -- 			[{lnum}, {col}, {off}, {curswant}]
-- -- 		This is like the return value of |getpos()| or |getcurpos()|,
-- -- 		but without the first item.
-- --
-- -- 		To position the cursor using {col} as the character count, use
-- -- 		|setcursorcharpos()|.
-- --
-- -- 		Does not change the jumplist.
-- -- 		{lnum} is used like with |getline()|, except that if {lnum} is
-- -- 		zero, the cursor will stay in the current line.
-- -- 		If {lnum} is greater than the number of lines in the buffer,
-- -- 		the cursor will be positioned at the last line in the buffer.
-- -- 		If {col} is greater than the number of bytes in the line,
-- -- 		the cursor will be positioned at the last character in the
-- -- 		line.
-- -- 		If {col} is zero, the cursor will stay in the current column.
-- -- 		If {curswant} is given it is used to set the preferred column
-- -- 		for vertical movement.  Otherwise {col} is used.
-- --
-- -- 		When 'virtualedit' is used {off} specifies the offset in
-- -- 		screen columns from the start of the character.  E.g., a
-- -- 		position within a <Tab> or after the last character.
-- -- 		Returns 0 when the position could be set, -1 otherwise.
-- end

return Cursor

-- nvim_win_get_tabpage({window})
