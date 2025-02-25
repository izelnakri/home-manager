-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local Telescope = require("telescope.builtin")
local String = require("izelnakri.utils.string")

MyTelescope = {
  searchManPages = function()
    local handler = io.popen("manpath")
    local manpath = handler:read("*a")
    handler:close()

    vim.print(String.split(manpath, ":"))
    Telescope.live_grep({
      search_dirs = String.split(manpath, ":"),
      prompt_title = "Search Man Pages",
    })

    -- https://github.com/arjunmahishi/flow.nvim/wiki/Flow-launcher check this for: apropos -M $(manpath) -r task
    -- verbose version: apropos -v -d -M $(manpath) -r task
    --
    -- Check this for extending telescope: https://github.com/HPRIOR/telescope-gpt
  end,
  fileExplorer = function()
    require("telescope").extensions.file_browser.file_browser({
      prompt_title = "File Explorer",
      cwd = "~",

      -- width = .25,

      -- layout_strategy = "horizontal",
      -- layout_config = {
      --   preview_width = 0.65
      -- }
    })

    -- {path}               (string)          dir to browse files from,
    --                                        `vim.fn.expanded` automatically
    --                                        (default: vim.loop.cwd())
    -- {cwd}                (string)          dir to browse folders from,
    --                                        `vim.fn.expanded` automatically
    --                                        (default: vim.loop.cwd())
    -- {cwd_to_path}        (boolean)         whether folder browser is
    --                                        launched from `path` rather
    --                                        than `cwd` (default: false)
    -- {grouped}            (boolean)         group initial sorting by
    --                                        directories and then files
    --                                        (default: false)
    -- {files}              (boolean)         start in file (true) or folder
    --                                        (false) browser (default: true)
    -- {add_dirs}           (boolean)         whether the file browser shows
    --                                        folders (default: true)
    -- {depth}              (number)          file tree depth to display,
    --                                        `false` for unlimited depth
    --                                        (default: 1)
    -- {auto_depth}         (boolean|number)  unlimit or set `depth` to
    --                                        `auto_depth` & unset grouped on
    --                                        prompt for file_browser
    --                                        (default: false)
    -- {select_buffer}      (boolean)         select current buffer if
    --                                        possible; may imply
    --                                        `hidden=true` (default: false)
    -- {hidden}             (table|boolean)   determines whether to show
    --                                        hidden files or not (default:
    --                                        `{ file_browser = false,
    --                                        folder_browser = false }`)
    -- {respect_gitignore}  (boolean)         induces slow-down w/ plenary
    --                                        finder (default: false, true if
    --                                        `fd` available)
    -- {no_ignore}          (boolean)         disable use of ignore files
    --                                        like
    --                                        .gitignore/.ignore/.fdignore
    --                                        (default: false, requires `fd`)
    -- {follow_symlinks}    (boolean)         traverse symbolic links, i.e.
    --                                        files and folders (default:
    --                                        false, only works with `fd`)
    -- {browse_files}       (function)        custom override for the file
    --                                        browser (default:
    --                                        |fb_finders.browse_files|)
    -- {browse_folders}     (function)        custom override for the folder
    --                                        browser (default:
    --                                        |fb_finders.browse_folders|)
    -- {hide_parent_dir}    (boolean)         hide `../` in the file browser
    --                                        (default: false)
    -- {collapse_dirs}      (boolean)         skip dirs w/ only single
    --                                        (possibly hidden) sub-dir in
    --                                        file_browser (default: false)
    -- {quiet}              (boolean)         surpress any notification from
    --                                        file_brower actions (default:
    --                                        false)
    -- {use_ui_input}       (boolean)         Use vim.ui.input() instead of
    --                                        vim.fn.input() or
    --                                        vim.fn.confirm() (default:
    --                                        true)
    -- {dir_icon}           (string)          change the icon for a directory
    --                                        (default: )
    -- {dir_icon_hl}        (string)          change the highlight group of
    --                                        dir icon (default: "Default")
    -- {display_stat}       (boolean|table)   ordered stat; see above notes,
    --                                        (default: `{ date = true, size
    --                                        = true, mode = true }`)
    -- {hijack_netrw}       (boolean)         use telescope file browser when
    --                                        opening directory paths; must
    --                                        be set on `setup` (default:
    --                                        false)
    -- {use_fd}             (boolean)         use `fd` if available over
    --                                        `plenary.scandir` (default:
    --                                        true)
    -- {git_status}         (boolean)         show the git status of files
    --                                        (default: true if `git`
    --                                        executable can be found)
    -- {prompt_path}        (boolean)         Show the current relative path
    --                                        from cwd as the prompt prefix.
    --                                        (default: false)
    -- {create_from_prompt} (boolean)         Create file/folder from prompt
    --                                        if no entry selected (default:
    --                                        true)
  end,

  -- search in vimwiki + neorg?
  --
  -- file explorer
}

vim.cmd("command! -nargs=0 Name execute ':!echo % | wl-copy'")
vim.cmd("command! RmSwp execute '!rm /var/tmp/*.swp'")
vim.cmd("command! Errors execute ':Telescope notify'")

-- NOTE: This makes LSP activated for the buffer:
local function augroup(name)
  return vim.api.nvim_create_augroup("my_custom_" .. name, { clear = true })
end

-- vim.on_key(function(key)
--   print("key", key)
-- end)

-- NOTE: instead try it with plenary on new buff(after disabling): https://github.com/nvim-lua/plenary.nvim
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("activate_lsp"),
  callback = function() -- NOTE: param event
    vim.cmd([[filetype detect]])
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufferline = require("bufferline")
    local elements = bufferline.get_elements().elements
    local harpoon = require("harpoon")
    local harpoon_list = harpoon:list()

    -- harpoon_list:clear()
    --
    -- for index, element in pairs(elements) do
    --   vim.print(index)
    --   harpoon_list.items[index] = {
    --     context = {
    --       col = 4,
    --       row = 4,
    --     },
    --     value = element.path,
    --   }
    -- end

    -- {
    --   elements = { {
    --       id = 3,
    --       name = "test.md",
    --       path = "/home/izelnakri/.config/home-manager/test.md"
    --     }, {
    --       id = 17,
    --       name = "harpoon.lua",
    --       path = "/home/izelnakri/.config/home-manager/static/.config/nvim/lua/plugins/harpoon.lua"
    --     }, {
    --       id = 647,
    --       name = "autocmds.lua",
    --       path = "/home/izelnakri/.config/home-manager/static/.config/nvim/lua/config/autocmds.lua"
    --     } },
    --   mode = "buffers"
    -- }

    -- vim.schedule(function()
    --   pcall(nvim_bufferline)
    -- end)
  end,
})

-- TODO: also hook into  local bd = require("mini.bufremove").delete

-- vim.api.nvim_create_autocmd("BufAdd", {
--   group = augroup("add_to_harpoon"),
--   callback = function(event)
--
--     -- require("harpoon"):list():add()
--
--     -- TODO: In future: replace harpoon data with bufferline
--     -- require("harpoon"):list():clear()
--     -- groups = require("bufferline.groups")
--     -- for _, group in pairs(groups.get_all()) do
--     --   vim.print(group)
--     --   -- require("harpoon"):list():add(group)
--     -- end
--     -- require("harpoon"):list():get_all()
--     -- for _, group in pairs(groups.get_all()) do
--     --   local group_hl, name = group.highlight, group.name
--     --   if group_hl and type(group_hl) == "table" then
--     --     local sep_name = fmt("%s_separator", name)
--     --     local label_name = fmt("%s_label", name)
--     --     local selected_name = fmt("%s_selected", name)
--     --     local visible_name = fmt("%s_visible", name)
--     --     hls[sep_name] = {
--     --       fg = group_hl.fg or group_hl.sp or hls.group_separator.fg,
--     --       bg = hls.fill.bg,
--     --     }
--     --     hls[label_name] = {
--     --       fg = hls.fill.bg,
--     --       bg = group_hl.fg or group_hl.sp or hls.group_separator.fg,
--     --     }
--     --
--     --     hls[name] = vim.tbl_extend("keep", group_hl, hls.buffer)
--     --     hls[visible_name] = vim.tbl_extend("keep", group_hl, hls.buffer_visible)
--     --     hls[selected_name] = vim.tbl_extend("keep", group_hl, hls.buffer_selected)
--     --
--     --     hls[name].hl_group = highlights.generate_name(name)
--     --     hls[sep_name].hl_group = highlights.generate_name(sep_name)
--     --     hls[label_name].hl_group = highlights.generate_name(label_name)
--     --     hls[visible_name].hl_group = highlights.generate_name(visible_name)
--     --     hls[selected_name].hl_group = highlights.generate_name(selected_name)
--     --   end
--     -- end
--   end,
-- })

-- vim.api.nvim_buf_line_count(get_main_file_buffer_id())
-- vim.o.lines
-- vim.api.nvim_win_set_height(vim.api.nvim_get_current_win(), vim.o.lines)
--
-- NOTE: Example to add stuff to current area
function _G.put_text(...)
  local objects = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

-- TODO: Maybe ad this: map <F5> :let &background = ( &background == "dark"? "light" : "dark" )<CR>

-- TODO: Make rustacean open cargo --doc open $doc open that thing
-- file:///home/izelnakri/Github/poem-tutorial/target/doc/poem_tutorial/struct.CatApi.html#method.index

-- TODO: Make a function that opens in offline-mode browser(devdocs) whats on hover (cargo doc --open, (elixir version), (deno docs version))
-- :InspectTree shows TreeSitter tree

-- " Compile rmarkdown
-- autocmd FileType rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>

-- TODO: Run tests, Expand macros, renderDiagnostics(?), joinLines, view crate graph

-- autocmd FileType rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>
