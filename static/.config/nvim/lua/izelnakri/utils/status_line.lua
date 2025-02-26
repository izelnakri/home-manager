StatusLine = {}

return StatusLine

-- NOTE: Each window has its status-line. Read up on it: status-line
-- Rulerformat

-- nvim_eval_statusline({str}, {opts})                   *nvim_eval_statusline()*
--     Evaluates statusline string.
--
--     Attributes: ~
--         |api-fast|
--
--     Parameters: ~
--       • {str}   Statusline string (see 'statusline').
--       • {opts}  Optional parameters.
--                 • winid: (number) |window-ID| of the window to use as context
--                   for statusline.
--                 • maxwidth: (number) Maximum width of statusline.
--                 • fillchar: (string) Character to fill blank spaces in the
--                   statusline (see 'fillchars'). Treated as single-width even
--                   if it isn't.
--                 • highlights: (boolean) Return highlight information.
--                 • use_winbar: (boolean) Evaluate winbar instead of statusline.
--                 • use_tabline: (boolean) Evaluate tabline instead of
--                   statusline. When true, {winid} is ignored. Mutually
--                   exclusive with {use_winbar}.
--                 • use_statuscol_lnum: (number) Evaluate statuscolumn for this
--                   line number instead of statusline.
--
--     Return: ~
--         Dictionary containing statusline information, with these keys:
--         • str: (string) Characters that will be displayed on the statusline.
--         • width: (number) Display width of the statusline.
--         • highlights: Array containing highlight information of the
--           statusline. Only included when the "highlights" key in {opts} is
--           true. Each element of the array is a |Dictionary| with these keys:
--           • start: (number) Byte index (0-based) of first character that uses
--             the highlight.
--           • group: (string) Name of highlight group.
--
