-- Essentially gets the cursor information. NOTE: Where does the other buf cols stored?!

--- @class WindowView
--- @field col integer Cursor column number
--- @field coladd integer Cursor column offset for 'virtualedit'
--- @field curswant integer Column for vertical movement (Note: the first column is zero, as opposed to what |getcurpos()| returns))
--- @field leftcol integer First column displayed; only used when 'wrap' is off
--- @field lnum integer Cursor line number
--- @field skipcol integer Total columns skipped of the view, usually 0
--- @field topfill integer Top filler lines of the view, only in diff mode, 0 otherwise
--- @field topline integer Top line number of the view
--- @field winid integer Associated windows id

WindowView = {}

--- @param win_or_winid? integer | Window
function WindowView.peek(win_or_winid)
  if win_or_winid == nil then
    local winid = vim.api.nvim_get_current_win()
    local window_view = vim.fn.winsaveview()

    return vim.tbl_extend("force", window_view, { winid = winid })
  end

  -- if ()

  -- NOTE: do this for specific window
  -- Recreate this from a buffer by checking which window a buffer is associated with and get the col, coll,add

  return {
    -- col
    coladd = 0,
    curswant = col,
    leftcol = 0, -- NOTE: handle wrap case
    -- lnum
    skipcol = 0, -- NOTE: handle skipped col case
    topfill = 0, -- NOTE: 0 most of the time unless there is diff
    -- topline = -- NOTE: get this as well, or autogenerate it from col and win height
  }
end

function WindowView.restore(window_view)
  return vim.fn.winrestview(window_view) -- NOTE: maybe remove winid addition
end

return WindowView

-- NOTE: How is the relationship between tabpage, windowview, window, buffer, cursor
