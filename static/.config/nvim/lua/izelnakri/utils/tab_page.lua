--- @class TabPage
--- @field tabnr number TabPage unique identifier
--- @field variables table<string, any> TabPage variables
--- @field windows number[] List of windownrs associated with the TabPage -- TODO: check is it winid or winnr
--- NOTE: Maybe add is_current

TabPage = {}

function TabPage.edit(tabnr)
  -- local path =
  -- return vim.cmd(":tabedit " .. path) -- NOTE: Check if this is legit or needed
end

function TabPage.peek(tabnr)
  if tabnr == nil then
    return vim.fn.gettabinfo(vim.api.nvim_win_get_tabpage(0))
  elseif tabnr > 0 then
    return vim.fn.gettabinfo(vim.api.nvim_win_get_tabpage(tabnr))
  end

  return error("TabPage.peek($tabnr) -> Invalid $tabnr provided:" .. tostring(tabnr))
end

function TabPage.peek_by(query)
  local all_tabpages = vim.fn.gettabinfo()

  return List.find(all_tabpages, function(tabpage)
    -- TODO: build the comparison function
    return tabpage
  end)
end

function TabPage.peek_all(query)
  local all_tabpages = vim.fn.gettabinfo()

  if query == nil then
    return all_tabpages
  end

  return List.reduce(all_tabpages, function(tabpage)
    -- TODO: build the comparison function
    return tabpage
  end)
end

-- Screen:height/Screen:width: vim.api.nvim_list_uis()[1].height

-- NOTE: TEST THESE CALLS:

-- NOTE: Open/close/change(?)

--- @params window integer | Window Window structs don't have tabpagenr, thus this function is needed
--- @return TabPage
function TabPage.peek_by_window(window)
  if type(window) == "number" then
    return TabPage.peek(vim.api.nvim_win_get_tabpage(window))
  end

  return TabPage.peek(vim.api.nvim_win_get_tabpage(window.winid))
end

function TabPage.is_current(tabpage)
  if tabpage == nil then
    return error("TabPage.is_current($tabpage) requires a $tabpage")
  elseif type(tabpage) == "number" then
    return TabPage.peek().tabnr == tabpage
  end

  return TabPage.peek().tabnr == tabpage.tabnr
end

--- @param tabpage TabPage | number Util method because vim.api.nvim_tabpage_is_valid API exists
--- @return boolean
function TabPage.exists(tabpage)
  if tabpage >= 0 then
    return vim.api.nvim_tabpage_is_valid(tabpage)
  end

  return vim.api.nvim_tabpage_is_valid(tabpage.tabnr)
end

function TabPage.set_current(tabpage)
  if type(tabpage) == "number" then
    return vim.api.nvim_set_current_tabpage(tabpage)
  else
    return vim.api.nvim_set_current_tabpage(tabpage.tabnr)
  end
end

function TabPage.get_current_window(tabpage)
  if type(tabpage) == "number" then
    return Window.peek(vim.api.nvim_tabpage_get_win(tabpage))
  else
    return Window.peek(vim.api.nvim_tabpage_get_win(tabpage.tabnr))
  end
end

function TabPage.set_current_window(tabpage, window)
  return vim.api.nvim_tabpage_set_win(tabpage, window)
end

function TabPage.get_buffers(tabpage)
  -- NOTE: Buffer might appear in more than one window
  -- TODO:
end

function TabPage.get_windows(tabpage)
  -- return vim.apinvim_tabpage_list_wins({tabpagenr})
  -- TODO:
end

function TabPage.get_layout(tabpage)
  if tabpage == 0 or tabpage == nil then
    return vim.fn.winlayout(TabPage.peek().tabnr)
  elseif type(tabpage) == "number" then
    return vim.fn.winlayout(tabpage)
  end

  return vim.fn.winlayout(tabpage.tabnr)
end

-- TODO: Check if loclist, jumplist and qflist does appear in the layout data structure:w

-- NOTE:
-- winlayout([{tabnr}])                                               *winlayout()*
-- 		The result is a nested List containing the layout of windows
-- 		in a tabpage.
--
-- 		Without {tabnr} use the current tabpage, otherwise the tabpage
-- 		with number {tabnr}. If the tabpage {tabnr} is not found,
-- 		returns an empty list.
--
-- 		For a leaf window, it returns: >
-- 			["leaf", {winid}]
-- <
-- 		For horizontally split windows, which form a column, it
-- 		returns: >
-- 			["col", [{nested list of windows}]]
-- <		For vertically split windows, which form a row, it returns: >
-- 			["row", [{nested list of windows}]]
-- <
-- 		Example: >vim
-- 			" Only one window in the tab page
-- 			echo winlayout()
-- <		 >
-- 			['leaf', 1000]
-- <		 >vim
-- 			" Two horizontally split windows
-- 			echo winlayout()
-- <		 >
-- 			['col', [['leaf', 1000], ['leaf', 1001]]]
-- <		 >vim
-- 			" The second tab page, with three horizontally split
-- 			" windows, with two vertically split windows in the
-- 			" middle window
-- 			echo winlayout(2)
-- <		 >
-- 			['col', [['leaf', 1002], ['row', [['leaf', 1003],
-- 					    ['leaf', 1001]]], ['leaf', 1000]]]
