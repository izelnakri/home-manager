-- TODO: Read windows.txt, check current window on tabpage, check is floating(relative)
-- winid 1639

--- @class Window
--- @field botline integer Bottom buffer line
--- @field bufnr integer Windows buffer number
--- @field height integer Windows height (excluding winbar)
--- @field loclist integer 1 if showing a location list
--- @field quickfix integer 1 if showing a quickfix or location list window
--- @field tabnr integer Windows tab page number
--- @field terminal integer 1 if a terminal window
--- @field textoff integer Number of columns on the left space, occupied by 'foldcolumn', 'signcolumn' and line
--- @field topline integer Top buffer line
--- @field variables table<string,any> Window-local variables
--- @field width integer Windows width
--- @field winbar integer 1 if the window has a toolbar(usually on the top), not statusline
--- @field wincol integer Leftmost X offset from the screen. Same as col in vim.fn.win_screenpos(winid)
--- @field winid integer Window id
--- @field winnr integer window number. Used in window switches, :exe $winnr .. "wincmd w" options
--- @field winrow integer Topmost Y offset from the screen. Same as row in vim.fn.win_screenpos(winid)
Window = {}

-- TODO: nvim_win_set_config very important to detach windows & manipulation

--- TODO: What should Window.set() target?
--- windowinfo keys(hopefully), window-local, or window-scoped options(?) - Probably Option module should do it, window variables(?)

---@param opts Window Window options
---@return Window
function Window:new(opts)
  self.__index = self

  return setmetatable(Object.assign({}, opts), self)
end

--- NOTE: Maybe add current if window is current window in tab page: Window.is_current(window)?

-- function Window.peek(winid, attrOrFunc) -- NOTE: is or has(more unified), has can be: Window.has(window, partialAttrOrFunct). TODO: Minimalist version
--   if winid == nil then
--     return vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
--   end
--
--   return vim.fn.getwininfo(window)
--   -- maybe: nvim_win_get_height({window})                          *nvim_win_get_height()*
--   -- nvim_win_get_number({window})                          *nvim_win_get_number()*
-- end

function Window.peek_all(opts) -- opts
  opts = opts or {} -- hidden, is_open?
end

--- @param window Window Target window to change its buffer
--- @param buffer Buffer Target buffer to change in the target window
--- @return Window Returns the target window with its buffer changed
function Window.change_buffer(window, buffer) end

return Window

-- nvim_win_get_tabpage({window}) ---> { tabpagenrs } -- 0 or windownr or window(?)

-- nvim_list_wins()                                            *nvim_list_wins()*
--     Gets the current list of window handles.
--
--     Return: ~
--         List of window handles

-- nvim_set_current_win({window})                        *nvim_set_current_win()*
--     Sets the current window.
--
--     Attributes: ~
--         not allowed when |textlock| is active or in the |cmdwin|
--
--     Parameters: ~
--       • {window}  Window handle

-- getwininfo([{winid}])                                             *getwininfo()*
-- 		Returns information about windows as a |List| with Dictionaries.
--
-- 		If {winid} is given Information about the window with that ID
-- 		is returned, as a |List| with one item.  If the window does not
-- 		exist the result is an empty list.
--
-- 		Without {winid} information about all the windows in all the
-- 		tab pages is returned.
--
-- 		Each List item is a |Dictionary| with the following entries:
-- 			botline		last complete displayed buffer line
-- 			bufnr		number of buffer in the window
-- 			height		window height (excluding winbar)
-- 			loclist		1 if showing a location list
-- 			quickfix	1 if quickfix or location list window
-- 			terminal	1 if a terminal window
-- 			tabnr		tab page number
-- 			topline		first displayed buffer line
-- 			variables	a reference to the dictionary with
-- 					window-local variables
-- 			width		window width
-- 			winbar		1 if the window has a toolbar, 0
-- 					otherwise
-- 			wincol		leftmost screen column of the window;
-- 					"col" from |win_screenpos()|
-- 			textoff		number of columns occupied by any
-- 					'foldcolumn', 'signcolumn' and line
-- 					number in front of the text
-- 			winid		|window-ID|
-- 			winnr		window number
-- 			winrow		topmost screen line of the window;
-- 					"row" from |win_screenpos()|

-- winlayout([{tabnr}])                                               *winlayout()*
-- The result is a nested List containing the layout of windows
-- in a tabpage.

-- win_screenpos({nr})                                            *win_screenpos()*

-- Window = {}

-- Read up on :h tabpages and :h windows

-- MUST INTERFACE FOR Data Util: peek(number or array of numbers), peek_all(obj or function), validate, peek_by(obj or function), util_funcs(open, close)
-- is vs has vs peek vs find

-- is() is clashes with type checks(?) of validate, match?
-- has_queries / probably not use
-- Instead can also use peek_cond because is_ and has_ returns a boolean, peek_cond returns truthy/false with less methods
-- Array.find(array, ()) and Array.peek(array, ()) -> converges

-- TODO: nvim_win_get_position({window}) --> gives off a position in window list, where is the list?! what is the col there of 120? First is row 0
-- TODO: nvim_win_get_tabpage({window}) -> Returns tabpageid
-- TODO: There is a tabpage with the window

-- function Window.has_left_window(winid) {
--
-- }
--
-- function Window.has_right_window(winid) {
--
-- }
--
-- function Window.has_below_window(winid) {
--
-- }
--
-- function Window.has_above_window(winid) {
--
-- }
--
-- -- NOTE: Window.is(opts) -- NOTE: is would be patterned with the window struct, OR has() OR has_attr() OR is_attr()
-- -- is or has provide no way to query opts, it gets assumed by the window struct
-- -- Check how Elixir does this, how Ecto does this, check how Ember-data does this
-- -- Check if these is methods are needed on the window struct
-- function Window.is_float() {
--
-- }
--
-- -- Window.peek(window, (window) => window.type == "float")
--
-- function Window.is_hidden() {
--
-- }
--
-- function Window.is_open() {
--
-- }
--
-- function Window.open() {
--
-- }
--
-- function Window.close() {
--
-- }
--
-- function Window.toggle() {
--
-- }
--
-- function Window.show()
--
-- end
--
-- function Window.hide()
--
-- end

-- TODO: set height, set width, set cursor, set buf

-- function Window.move(window, direction)

-- Tabpage(?)

-- vim.api.nvim_open_win(121, false, { relative = "editor", row = 15, col = 42, width = 199, height = 52  })
--
-- -- position: vim.api.nvim_get_position
-- 1038
--
-- nvim}_open_win({buffer}, {enter}, {config})                   *nvim_open_win()*
--
--     Example (Lua): window-relative float >lua
--         vim.api.nvim_open_win(0, false,
--           {relative='win', row=3, col=3, width=12, height=3})
-- <
--
--     Example (Lua): buffer-relative float (travels as buffer is scrolled) >lua
--         vim.api.nvim_open_win(0, false,
--           {relative='win', width=12, height=3, bufpos={100,10}})
-- <
--
--     Example (Lua): vertical split left of the current window >lua
--         vim.api.nvim_open_win(0, false, {
--           split = 'left',
--           win = 0
--         })
-- <
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {buffer}  Buffer to display, or 0 for current buffer
--       • {enter}   Enter the window (make it the current window)
--       • {config}  Map defining the window configuration. Keys:
--                   • relative: Sets the window layout to "floating", placed at
--                     (row,col) coordinates relative to:
--                     • "editor" The global editor grid
--                     • "win" Window given by the `win` field, or current
--                       window.
--                     • "cursor" Cursor position in current window.
--                     • "mouse" Mouse position
--                   • win: |window-ID| window to split, or relative window when
--                     creating a float (relative="win").
--                   • anchor: Decides which corner of the float to place at
--                     (row,col):
--                     • "NW" northwest (default)
--                     • "NE" northeast
--                     • "SW" southwest
--                     • "SE" southeast
--                   • width: Window width (in character cells). Minimum of 1.
--                   • height: Window height (in character cells). Minimum of 1.
--                   • bufpos: Places float relative to buffer text (only when
--                     relative="win"). Takes a tuple of zero-indexed
--                     `[line, column]`. `row` and `col` if given are applied
--                     relative to this position, else they default to:
--                     • `row=1` and `col=0` if `anchor` is "NW" or "NE"
--                     • `row=0` and `col=0` if `anchor` is "SW" or "SE" (thus
--                       like a tooltip near the buffer text).
--                   • row: Row position in units of "screen cell height", may be
--                     fractional.
--                   • col: Column position in units of "screen cell width", may
--                     be fractional.
--                   • focusable: Enable focus by user actions (wincmds, mouse
--                     events). Defaults to true. Non-focusable windows can be
--                     entered by |nvim_set_current_win()|.
--                   • external: GUI should display the window as an external
--                     top-level window. Currently accepts no other positioning
--                     configuration together with this.
--                   • zindex: Stacking order. floats with higher `zindex` go on
--                     top on floats with lower indices. Must be larger than
--                     zero. The following screen elements have hard-coded
--                     z-indices:
--                     • 100: insert completion popupmenu
--                     • 200: message scrollback
--                     • 250: cmdline completion popupmenu (when
--                       wildoptions+=pum) The default value for floats are 50.
--                       In general, values below 100 are recommended, unless
--                       there is a good reason to overshadow builtin elements.
--                   • style: (optional) Configure the appearance of the window.
--                     Currently only supports one value:
--                     • "minimal" Nvim will display the window with many UI
--                       options disabled. This is useful when displaying a
--                       temporary float where the text should not be edited.
--                       Disables 'number', 'relativenumber', 'cursorline',
--                       'cursorcolumn', 'foldcolumn', 'spell' and 'list'
--                       options. 'signcolumn' is changed to `auto` and
--                       'colorcolumn' is cleared. 'statuscolumn' is changed to
--                       empty. The end-of-buffer region is hidden by setting
--                       `eob` flag of 'fillchars' to a space char, and clearing
--                       the |hl-EndOfBuffer| region in 'winhighlight'.
--                   • border: Style of (optional) window border. This can either
--                     be a string or an array. The string values are
--                     • "none": No border (default).
--                     • "single": A single line box.
--                     • "double": A double line box.
--                     • "rounded": Like "single", but with rounded corners
--                       ("╭" etc.).
--                     • "solid": Adds padding by a single whitespace cell.
--                     • "shadow": A drop shadow effect by blending with the
--                       background.
--                     • If it is an array, it should have a length of eight or
--                       any divisor of eight. The array will specify the eight
--                       chars building up the border in a clockwise fashion
--                       starting with the top-left corner. As an example, the
--                       double box style could be specified as: >
--                       [ "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" ].
-- <
--                       If the number of chars are less than eight, they will be
--                       repeated. Thus an ASCII border could be specified as >
--                       [ "/", "-", \"\\\\\", "|" ],
-- <
--                       or all chars the same as >
--                       [ "x" ].
-- <
--                     An empty string can be used to turn off a specific border,
--                     for instance, >
--                      [ "", "", "", ">", "", "", "", "<" ]
-- <
--                     will only make vertical borders but not horizontal ones.
--                     By default, `FloatBorder` highlight is used, which links
--                     to `WinSeparator` when not defined. It could also be
--                     specified by character: >
--                      [ ["+", "MyCorner"], ["x", "MyBorder"] ].
-- <
--                   • title: Title (optional) in window border, string or list.
--                     List should consist of `[text, highlight]` tuples. If
--                     string, the default highlight group is `FloatTitle`.
--                   • title_pos: Title position. Must be set with `title`
--                     option. Value can be one of "left", "center", or "right".
--                     Default is `"left"`.
--                   • footer: Footer (optional) in window border, string or
--                     list. List should consist of `[text, highlight]` tuples.
--                     If string, the default highlight group is `FloatFooter`.
--                   • footer_pos: Footer position. Must be set with `footer`
--                     option. Value can be one of "left", "center", or "right".
--                     Default is `"left"`.
--                   • noautocmd: If true then all autocommands are blocked for
--                     the duration of the call.
--                   • fixed: If true when anchor is NW or SW, the float window
--                     would be kept fixed even if the window would be truncated.
--                   • hide: If true the floating window will be hidden.
--                   • vertical: Split vertically |:vertical|.
--                   • split: Split direction: "left", "right", "above", "below".
--
--     Return: ~
--         Window handle, or 0 on error
--
--
--
--
--
-- -- NOTE: not sure if I need this utils yet, however basically:
-- -- :botright vnew | opens it on right instead of bottom right!
-- -- NOTE: Following works:!
-- -- :redir @a
-- -- :imap
-- -- :redir END
-- -- :new
-- -- :put a
-- -- NOTE: read abbraviation
-- -- OR = :vnew | :put=execute('verbose map')
-- -- OR = :vnew | :put=system('rg --help')
-- -- OR = :ab p :put=execute('
-- -- OR = :ab o :put=system('
--
-- -- nvim_put() !!
-- --
-- -- I can adjust "prefilled width/height" of windows
-- -- introduce complicated window commands here first as lua methods, then Commands
-- --
-- -- require("lazy.util").float_term({ "htop" })
-- --
-- --
-- --
-- -- local toggle_opts = {}
-- -- local win = vim.api.nvim_list_uis()
-- -- local width = 50
-- -- local height = 8
-- -- local bufnr = vim.api.nvim_create_buf(false, true)
-- -- local win_id = vim.api.nvim_open_win(bufnr, true, {
-- --     relative = "editor",
-- --     title = toggle_opts.title or "Harpoon",
-- --     title_pos = toggle_opts.title_pos or "left",
-- --     row = math.floor(((vim.o.lines - height) / 2) - 1),
-- --     col = math.floor((vim.o.columns - width) / 2),
-- --     width = width,
-- --     height = height,
-- --     style = "minimal",
-- --     border = toggle_opts.border or "single",
-- -- })
-- --
-- --
-- --
-- --
-- --require("telescope").setup {
-- --   create_layout = function(picker)
-- --     local function create_window(enter, width, height, row, col, title)
-- --       local bufnr = vim.api.nvim_create_buf(false, true)
-- --       local winid = vim.api.nvim_open_win(bufnr, enter, {
-- --         style = "minimal",
-- --         relative = "editor",
-- --         width = width,
-- --         height = height,
-- --         row = row,
-- --         col = col,
-- --         border = "single",
-- --         title = title,
-- --       })
-- --
-- --       vim.wo[winid].winhighlight = "Normal:Normal"
-- --
-- --       return Layout.Window {
-- --         bufnr = bufnr,
-- --         winid = winid,
-- --       }
-- --     end
-- --
-- --     local function destory_window(window)
-- --       if window then
-- --         if vim.api.nvim_win_is_valid(window.winid) then
-- --           vim.api.nvim_win_close(window.winid, true)
-- --         end
-- --         if vim.api.nvim_buf_is_valid(window.bufnr) then
-- --           vim.api.nvim_buf_delete(window.bufnr, { force = true })
-- --         end
-- --       end
-- --     end
-- --
-- --     local layout = Layout {
-- --       picker = picker,
-- --       mount = function(self)
-- --         self.results = create_window(false, 40, 20, 0, 0, "Results")
-- --         self.preview = create_window(false, 40, 23, 0, 42, "Preview")
-- --         self.prompt = create_window(true, 40, 1, 22, 0, "Prompt")
-- --       end,
-- --       unmount = function(self)
-- --         destory_window(self.results)
-- --         destory_window(self.preview)
-- --         destory_window(self.prompt)
-- --       end,
-- --       update = function(self) end,
-- --     }
-- --
-- --     return layout
-- --   end,
-- -- }

-- getjumplist([{winnr} [, {tabnr}]])                               *getjumplist()*
-- 		Returns the |jumplist| for the specified window.
--
-- 		Without arguments use the current window.
-- 		With {winnr} only use this window in the current tab page.
-- 		{winnr} can also be a |window-ID|.
-- 		With {winnr} and {tabnr} use the window in the specified tab
-- 		page.  If {winnr} or {tabnr} is invalid, an empty list is
-- 		returned.
--
-- 		The returned list contains two entries: a list with the jump
-- 		locations and the last used jump position number in the list.
-- 		Each entry in the jump location list is a dictionary with
-- 		the following entries:
-- 			bufnr		buffer number
-- 			col		column number
-- 			coladd		column offset for 'virtualedit'
-- 			filename	filename if available
-- 			lnum		line number

-- getloclist({nr} [, {what}])                                       *getloclist()*
-- 		Returns a |List| with all the entries in the location list for
-- 		window {nr}.  {nr} can be the window number or the |window-ID|.
-- 		When {nr} is zero the current window is used.
--
-- 		For a location list window, the displayed location list is
-- 		returned.  For an invalid window number {nr}, an empty list is
-- 		returned. Otherwise, same as |getqflist()|.
--
-- 		If the optional {what} dictionary argument is supplied, then
-- 		returns the items listed in {what} as a dictionary. Refer to
-- 		|getqflist()| for the supported items in {what}.
--
-- 		In addition to the items supported by |getqflist()| in {what},
-- 		the following item is supported by |getloclist()|:
--
-- 			filewinid	id of the window used to display files
-- 					from the location list. This field is
-- 					applicable only when called from a
-- 					location list window. See
-- 					|location-list-file-window| for more
-- 					details.
--
-- 		Returns a |Dictionary| with default values if there is no
-- 		location list for the window {nr}.
-- 		Returns an empty Dictionary if window {nr} does not exist.
--
-- 		Examples (See also |getqflist-examples|): >vim
-- 			echo getloclist(3, {'all': 0})
-- 			echo getloclist(5, {'filewinid': 0})

-- win_gotoid({expr})                                                *win_gotoid()*
-- 		Go to window with ID {expr}.  This may also change the current
-- 		tabpage.
-- 		Return TRUE if successful, FALSE if the window cannot be found.

-- win_id2tabwin({expr})                                          *win_id2tabwin()*
-- 		Return a list with the tab number and window number of window
-- 		with ID {expr}: [tabnr, winnr].
-- 		Return [0, 0] if the window cannot be found.
--
-- win_id2win({expr})                                                *win_id2win()*
-- 		Return the window number of window with ID {expr}.
-- 		Return 0 if the window cannot be found in the current tabpage.

-- NOTE:
-- winbufnr({nr})                                                      *winbufnr()*
-- 		The result is a Number, which is the number of the buffer
-- 		associated with window {nr}.  {nr} can be the window number or
-- 		the |window-ID|.
-- 		When {nr} is zero, the number of the buffer in the current
-- 		window is returned.
-- 		When window {nr} doesn't exist, -1 is returned.
-- 		Example: >vim
-- 		  echo "The file in the current window is " .. bufname(winbufnr(0))

-- wincol()                                                              *wincol()*
-- 		The result is a Number, which is the virtual column of the
-- 		cursor in the window.  This is counting screen cells from the
-- 		left side of the window.  The leftmost column is one.

-- winheight({nr})                                                    *winheight()*
-- 		The result is a Number, which is the height of window {nr}.
-- 		{nr} can be the window number or the |window-ID|.
-- 		When {nr} is zero, the height of the current window is
-- 		returned.  When window {nr} doesn't exist, -1 is returned.
-- 		An existing window always has a height of zero or more.
-- 		This excludes any window toolbar line.
-- 		Examples: >vim
-- 		  echo "The current window has " .. winheight(0) .. " lines."

-- winnr([{arg}])                                                         *winnr()*
-- 		The result is a Number, which is the number of the current
-- 		window.  The top window has number 1.
-- 		Returns zero for a popup window.
--
-- 		The optional argument {arg} supports the following values:
-- 			$	the number of the last window (the window
-- 				count).
-- 			#	the number of the last accessed window (where
-- 				|CTRL-W_p| goes to).  If there is no previous
-- 				window or it is in another tab page 0 is
-- 				returned.  May refer to the current window in
-- 				some cases (e.g. when evaluating 'statusline'
-- 				expressions).
-- 			{N}j	the number of the Nth window below the
-- 				current window (where |CTRL-W_j| goes to).
-- 			{N}k	the number of the Nth window above the current
-- 				window (where |CTRL-W_k| goes to).
-- 			{N}h	the number of the Nth window left of the
-- 				current window (where |CTRL-W_h| goes to).
-- 			{N}l	the number of the Nth window right of the
-- 				current window (where |CTRL-W_l| goes to).
-- 		The number can be used with |CTRL-W_w| and ":wincmd w"
-- 		|:wincmd|.
-- 		When {arg} is invalid an error is given and zero is returned.
-- 		Also see |tabpagewinnr()| and |win_getid()|.
-- 		Examples: >vim
-- 			let window_count = winnr('$')
-- 			let prev_window = winnr('#')
-- 			let wnum = winnr('3k')

-- nvim_win_call({window}, {fun})                               *nvim_win_call()*
--     Calls a function with window as temporary current window.
--
--     Attributes: ~
--         Lua |vim.api| only
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {fun}     Function to call inside the window (currently Lua callable
--                   only)
--
--     Return: ~
--         Return value of function.
--
--     See also: ~
--       • |win_execute()|
--       • |nvim_buf_call()|
--
-- nvim_win_close({window}, {force})                           *nvim_win_close()*
--     Closes the window (like |:close| with a |window-ID|).
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {force}   Behave like `:close!` The last window of a buffer with
--                   unwritten changes can be closed. The buffer will become
--                   hidden, even if 'hidden' is not set.
--
--
--
-- nvim_win_get_buf({window})                                *nvim_win_get_buf()*
--     Gets the current buffer in a window
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         Buffer handle

-- nvim_win_get_number({window})                          *nvim_win_get_number()*
--     Gets the window number
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         Window number
--
-- nvim_win_get_position({window})                      *nvim_win_get_position()*
--     Gets the window position in display cells. First position is zero.
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         (row, col) tuple with the window position

-- nvim_win_hide({window})                                      *nvim_win_hide()*
--     Closes the window and hide the buffer it contains (like |:hide| with a
--     |window-ID|).
--
--     Like |:hide| the buffer becomes hidden unless another window is editing
--     it, or 'bufhidden' is `unload`, `delete` or `wipe` as opposed to |:close|
--     or |nvim_win_close()|, which will close the buffer.
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
-- nvim_win_is_valid({window})                              *nvim_win_is_valid()*
--     Checks if a window is valid
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         true if the window is valid, false otherwise
--
-- nvim_win_set_buf({window}, {buffer})                      *nvim_win_set_buf()*
--     Sets the current buffer in a window, without side effects
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {buffer}  Buffer handle

-- nvim_win_set_width({window}, {width})                   *nvim_win_set_width()*
--     Sets the window width. This will only succeed if the screen is split vertically.
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {width}   Width as a count of columns

-- nvim__redraw({opts})                                          *nvim__redraw()*
--     EXPERIMENTAL: this API may change in the future.
--
--     Instruct Nvim to redraw various components.
--
--     Parameters: ~
--       • {opts}  Optional parameters.
--                 • win: Target a specific |window-ID| as described below.
--                 • buf: Target a specific buffer number as described below.
--                 • flush: Update the screen with pending updates.
--                 • valid: When present mark `win`, `buf`, or all windows for
--                   redraw. When `true`, only redraw changed lines (useful for
--                   decoration providers). When `false`, forcefully redraw.
--                 • range: Redraw a range in `buf`, the buffer in `win` or the
--                   current buffer (useful for decoration providers). Expects a
--                   tuple `[first, last]` with the first and last line number of
--                   the range, 0-based end-exclusive |api-indexing|.
--                 • cursor: Immediately update cursor position on the screen in
--                   `win` or the current window.
--                 • statuscolumn: Redraw the 'statuscolumn' in `buf`, `win` or
--                   all windows.
--                 • statusline: Redraw the 'statusline' in `buf`, `win` or all
--                   windows.
--                 • winbar: Redraw the 'winbar' in `buf`, `win` or all windows.
--                 • tabline: Redraw the 'tabline'.
--
--     See also: ~
--       • |:redraw|
--
-- ========
-- Win Config Options
-- ========

-- nvim_open_win({buffer}, {enter}, {config})                   *nvim_open_win()*
--     Opens a new split window, or a floating window if `relative` is specified,
--     or an external window (managed by the UI) if `external` is specified.
--
--     Floats are windows that are drawn above the split layout, at some anchor
--     position in some other window. Floats can be drawn internally or by
--     external GUI with the |ui-multigrid| extension. External windows are only
--     supported with multigrid GUIs, and are displayed as separate top-level
--     windows.
--
--     For a general overview of floats, see |api-floatwin|.
--
--     The `width` and `height` of the new window must be specified when opening
--     a floating window, but are optional for normal windows.
--
--     If `relative` and `external` are omitted, a normal "split" window is
--     created. The `win` property determines which window will be split. If no
--     `win` is provided or `win == 0`, a window will be created adjacent to the
--     current window. If -1 is provided, a top-level split will be created.
--     `vertical` and `split` are only valid for normal windows, and are used to
--     control split direction. For `vertical`, the exact direction is determined
--     by |'splitright'| and |'splitbelow'|. Split windows cannot have
--     `bufpos`/`row`/`col`/`border`/`title`/`footer` properties.
--
--     With relative=editor (row=0,col=0) refers to the top-left corner of the
--     screen-grid and (row=Lines-1,col=Columns-1) refers to the bottom-right
--     corner. Fractional values are allowed, but the builtin implementation
--     (used by non-multigrid UIs) will always round down to nearest integer.
--
--     Out-of-bounds values, and configurations that make the float not fit
--     inside the main editor, are allowed. The builtin implementation truncates
--     values so floats are fully within the main screen grid. External GUIs
--     could let floats hover outside of the main window like a tooltip, but this
--     should not be used to specify arbitrary WM screen positions.
--
--     Example (Lua): window-relative float >lua
--         vim.api.nvim_open_win(0, false,
--           {relative='win', row=3, col=3, width=12, height=3})
-- <
--
--     Example (Lua): buffer-relative float (travels as buffer is scrolled) >lua
--         vim.api.nvim_open_win(0, false,
--           {relative='win', width=12, height=3, bufpos={100,10}})
-- <
--
--     Example (Lua): vertical split left of the current window >lua
--         vim.api.nvim_open_win(0, false, {
--           split = 'left',
--           win = 0
--         })
-- <
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {buffer}  Buffer to display, or 0 for current buffer
--       • {enter}   Enter the window (make it the current window)
--       • {config}  Map defining the window configuration. Keys:
--                   • relative: Sets the window layout to "floating", placed at
--                     (row,col) coordinates relative to:
--                     • "editor" The global editor grid
--                     • "win" Window given by the `win` field, or current
--                       window.
--                     • "cursor" Cursor position in current window.
--                     • "mouse" Mouse position
--                   • win: |window-ID| window to split, or relative window when
--                     creating a float (relative="win").
--                   • anchor: Decides which corner of the float to place at
--                     (row,col):
--                     • "NW" northwest (default)
--                     • "NE" northeast
--                     • "SW" southwest
--                     • "SE" southeast
--                   • width: Window width (in character cells). Minimum of 1.
--                   • height: Window height (in character cells). Minimum of 1.
--                   • bufpos: Places float relative to buffer text (only when
--                     relative="win"). Takes a tuple of zero-indexed
--                     `[line, column]`. `row` and `col` if given are applied
--                     relative to this position, else they default to:
--                     • `row=1` and `col=0` if `anchor` is "NW" or "NE"
--                     • `row=0` and `col=0` if `anchor` is "SW" or "SE" (thus
--                       like a tooltip near the buffer text).
--                   • row: Row position in units of "screen cell height", may be
--                     fractional.
--                   • col: Column position in units of "screen cell width", may
--                     be fractional.
--                   • focusable: Enable focus by user actions (wincmds, mouse
--                     events). Defaults to true. Non-focusable windows can be
--                     entered by |nvim_set_current_win()|.
--                   • external: GUI should display the window as an external
--                     top-level window. Currently accepts no other positioning
--                     configuration together with this.
--                   • zindex: Stacking order. floats with higher `zindex` go on
--                     top on floats with lower indices. Must be larger than
--                     zero. The following screen elements have hard-coded
--                     z-indices:
--                     • 100: insert completion popupmenu
--                     • 200: message scrollback
--                     • 250: cmdline completion popupmenu (when
--                       wildoptions+=pum) The default value for floats are 50.
--                       In general, values below 100 are recommended, unless
--                       there is a good reason to overshadow builtin elements.
--                   • style: (optional) Configure the appearance of the window.
--                     Currently only supports one value:
--                     • "minimal" Nvim will display the window with many UI
--                       options disabled. This is useful when displaying a
--                       temporary float where the text should not be edited.
--                       Disables 'number', 'relativenumber', 'cursorline',
--                       'cursorcolumn', 'foldcolumn', 'spell' and 'list'
--                       options. 'signcolumn' is changed to `auto` and
--                       'colorcolumn' is cleared. 'statuscolumn' is changed to
--                       empty. The end-of-buffer region is hidden by setting
--                       `eob` flag of 'fillchars' to a space char, and clearing
--                       the |hl-EndOfBuffer| region in 'winhighlight'.
--                   • border: Style of (optional) window border. This can either
--                     be a string or an array. The string values are
--                     • "none": No border (default).
--                     • "single": A single line box.
--                     • "double": A double line box.
--                     • "rounded": Like "single", but with rounded corners
--                       ("╭" etc.).
--                     • "solid": Adds padding by a single whitespace cell.
--                     • "shadow": A drop shadow effect by blending with the
--                       background.
--                     • If it is an array, it should have a length of eight or
--                       any divisor of eight. The array will specify the eight
--                       chars building up the border in a clockwise fashion
--                       starting with the top-left corner. As an example, the
--                       double box style could be specified as: >
--                       [ "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" ].
-- <
--                       If the number of chars are less than eight, they will be
--                       repeated. Thus an ASCII border could be specified as >
--                       [ "/", "-", \"\\\\\", "|" ],
-- <
--                       or all chars the same as >
--                       [ "x" ].
-- <
--                     An empty string can be used to turn off a specific border,
--                     for instance, >
--                      [ "", "", "", ">", "", "", "", "<" ]
-- <
--                     will only make vertical borders but not horizontal ones.
--                     By default, `FloatBorder` highlight is used, which links
--                     to `WinSeparator` when not defined. It could also be
--                     specified by character: >
--                      [ ["+", "MyCorner"], ["x", "MyBorder"] ].
-- <
--                   • title: Title (optional) in window border, string or list.
--                     List should consist of `[text, highlight]` tuples. If
--                     string, the default highlight group is `FloatTitle`.
--                   • title_pos: Title position. Must be set with `title`
--                     option. Value can be one of "left", "center", or "right".
--                     Default is `"left"`.
--                   • footer: Footer (optional) in window border, string or
--                     list. List should consist of `[text, highlight]` tuples.
--                     If string, the default highlight group is `FloatFooter`.
--                   • footer_pos: Footer position. Must be set with `footer`
--                     option. Value can be one of "left", "center", or "right".
--                     Default is `"left"`.
--                   • noautocmd: If true then all autocommands are blocked for
--                     the duration of the call.
--                   • fixed: If true when anchor is NW or SW, the float window
--                     would be kept fixed even if the window would be truncated.
--                   • hide: If true the floating window will be hidden.
--                   • vertical: Split vertically |:vertical|.
--                   • split: Split direction: "left", "right", "above", "below".
--
--     Return: ~
--         Window handle, or 0 on error
--
-- nvim_win_get_config({window})                          *nvim_win_get_config()*
--     Gets window configuration.
--
--     The returned value may be given to |nvim_open_win()|.
--
--     `relative` is empty for normal windows.
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--
--     Return: ~
--         Map defining the window configuration, see |nvim_open_win()|
--
-- nvim_win_set_config({window}, {config})                *nvim_win_set_config()*
--     Configures window layout. Cannot be used to move the last window in a
--     tabpage to a different one.
--
--     When reconfiguring a window, absent option keys will not be changed.
--     `row`/`col` and `relative` must be reconfigured together.
--
--     Parameters: ~
--       • {window}  Window handle, or 0 for current window
--       • {config}  Map defining the window configuration, see |nvim_open_win()|
--
--     See also: ~
--       • |nvim_open_win()|

-- TODO: READ: /home/izelnakri/Github/neotest/lua/neotest/lib/ui/float.lua
