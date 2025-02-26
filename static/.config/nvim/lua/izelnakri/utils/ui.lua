UI = {}

return UI

-- nvim_get_mode() { blocking: bool, mode: string(ex. "n") }

-- input, inputlist, selection(with telescope)

-- nvim_ui_attach({width}, {height}, {options})                *nvim_ui_attach()*
--     Activates UI events on the channel.
--
--     Entry point of all UI clients. Allows |--embed| to continue startup.
--     Implies that the client is ready to show the UI. Adds the client to the
--     list of UIs. |nvim_list_uis()|
--
--     Note: ~
--       • If multiple UI clients are attached, the global screen dimensions
--         degrade to the smallest client. E.g. if client A requests 80x40 but
--         client B requests 200x100, the global screen has size 80x40.
--
--     Attributes: ~
--         |RPC| only
--
--     Parameters: ~
--       • {width}    Requested screen columns
--       • {height}   Requested screen rows
--       • {options}  |ui-option| map
--
-- nvim_ui_detach()                                            *nvim_ui_detach()*
--     Deactivates UI events on the channel.
--
--     Removes the client from the list of UIs. |nvim_list_uis()|
--
--     Attributes: ~
--         |RPC| only

-- nvim_ui_pum_set_bounds({width}, {height}, {row}, {col})
--     Tells Nvim the geometry of the popupmenu, to align floating windows with
--     an external popup menu.
--
--     Note that this method is not to be confused with
--     |nvim_ui_pum_set_height()|, which sets the number of visible items in the
--     popup menu, while this function sets the bounding box of the popup menu,
--     including visual elements such as borders and sliders. Floats need not use
--     the same font size, nor be anchored to exact grid corners, so one can set
--     floating-point numbers to the popup menu geometry.
--
--     Attributes: ~
--         |RPC| only
--
--     Parameters: ~
--       • {width}   Popupmenu width.
--       • {height}  Popupmenu height.
--       • {row}     Popupmenu row.
--       • {col}     Popupmenu height.
--
-- nvim_ui_pum_set_height({height})                    *nvim_ui_pum_set_height()*
--     Tells Nvim the number of elements displaying in the popupmenu, to decide
--     <PageUp> and <PageDown> movement.
--
--     Attributes: ~
--         |RPC| only
--
--     Parameters: ~
--       • {height}  Popupmenu height, must be greater than zero.
--
-- nvim_ui_set_focus({gained})                              *nvim_ui_set_focus()*
--     Tells the nvim server if focus was gained or lost by the GUI
--
--     Attributes: ~
--         |RPC| only
