local bufferline = require("izelnakri.pickers.bufferline")

-- TODO: <C-t> SHOULD MAKE THE EXISTING BUFFER LISTED!
-- NOTE: fix so that normal mode is possible?
-- NOTE: Maybe add <C-q> exit each time, or <Esc><Esc>, or Terminal toggle/hide keybind

-- actions.edit_search_line & actions.set_search_line -> changes the text on the prompt

-- NOTE: utils.get_os_command_output({ "git", "restore", "--staged", selection.value }, cwd)

-- NOTE: Git branch management can be done via telescope . Then needed(staging, logs, interactive rebase)
-- NOTE: Git staging management with telescope(investigate | probably not)

-- actions.insert_original_cWORD interesting maybe for future picker design

-- the :verbose imap <cr> finally exposed it, i basically just replaced it with a much better non conflicting plugin windwp/nvim-autopairs.

-- NOTE: Add: commands, lsp(? seems like better for debugging, maybe lsp (also workplace) symbols), keymaps, command_history, search_history(?), man_pages({ man_cmd = 'apropos ""' (task doesnt show up) })
-- each picker has also mappings on pickers = { find_files = { mappings = { i = { } } } } or attach_mappings
-- marks(?), registers(?), keymaps(?), filetypes(?), highlights(?), autocommands(?), undolist(?)
-- Create full_history telescope of all telescope actions(?),
local Builtin = {
  find_files = function(opts)
    return function()
      return require("telescope.builtin").find_files(vim.tbl_extend("force", {
        hidden = true,
      }, opts))
    end
  end,
  live_grep = function(opts)
    return function()
      return require("telescope.builtin").live_grep(vim.tbl_extend("force", {
        vimgrep_arguments = table.insert(require("telescope.config").values.vimgrep_arguments, "--hidden"),
        attach_mappings = function(_, map)
          local actions = require("telescope.actions")

          map("i", "<c-space>", actions.toggle_selection)

          return true
        end,
      }, opts))
    end
  end,
  bufferline = bufferline,
  -- NOTE: Think about session switcher, create/open/close/change -> move to zellij
}

return {
  {
    "nvim-telescope/telescope.nvim", -- Fuzzy Finder (files, lsp, etc), `:help telescope` and `:help telescope.setup()`
    version = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        enabled = vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1,
        build = vim.fn.executable("make") == 1 and "make"
          or "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
      },
      -- { "nvim-telescope/telescope-ui-select.nvim" },
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    keys = function(_, keys)
      local builtin = require("telescope.builtin")
      local List = require("izelnakri.utils.list")

      -- TODO: Test this without List.merge for speed
      return List.concat(keys, {
        {
          "<leader>sbf",
          Builtin.bufferline(),
          desc = "[S]elect [b]uffer [f]iles",
        },
        { "<leader>sh", builtin.help_tags, desc = "[S]earch [h]elp" },
        { "<leader>sk", builtin.keymaps, desc = "[S]earch [k]eymaps" }, -- TODO: modes, it should also check "n" only, "i" only, case insensitive, doesnt source all keymaps(?)
        {
          "<leader>sf",
          Builtin.find_files({
            follow = true,
            no_ignore = true,
            no_ignore_parent = true,
          }),
          desc = "[S]earch project [f]iles",
        },
        {
          "<leader>sF",
          Builtin.find_files({
            cwd = vim.env.HOME,
            find_command = function(_)
              return { "fd", "-tf", "-td", "-d", "4", "--color", "never" }
            end,
          }),
          desc = "[S]elect $HOME files",
        },
        {
          "<leader>sg",
          Builtin.live_grep({
            cwd = vim.fn.getcwd(),
            prompt_title = "[S]earch project files by [g]rep",
          }),
          desc = "[S]earch project files by [g]rep",
        },
        {
          "<leader>sG",
          Builtin.live_grep({
            cwd = "~",
            prompt_title = "[S]earch $HOME files by [g]rep",
          }),
          desc = "[S]earch $HOME files by [g]rep",
        },
        {
          "<leader>s/f", -- NOTE: sr reserved for register
          Builtin.find_files({
            cwd = "/",
            find_command = function(_)
              return { "fd", "-tf", "-td", "-d", "4", "--color", "never" }
            end,
          }),
          desc = "[S]elect files on [/]",
        },
        {
          "<leader>s/g",
          Builtin.live_grep({
            cwd = "/",
            prompt_title = "[S]earch [/] files by [g]rep",
          }),
          desc = "[S]earch [/] files by [g]rep",
        },
        {
          "<leader>ssf",
          Builtin.find_files({
            cwd = "/nix",
            find_command = function(_)
              return { "fd", "-tf", "-td", "-d", "4", "--color", "never" }
            end,
          }),
          desc = "[S]elect nix [s]tore files",
        },
        {
          "<leader>ssg",
          Builtin.live_grep({
            cwd = "/nix",
            prompt_title = "[S]earch nix [s]tore by [g]rep",
          }),
          desc = "[S]earch nix [s]storesgby [g]rep",
        },
        {
          "<leader>spf",
          Builtin.find_files({
            cwd = "~/.local/share/nvim/lazy",
            find_command = function(_)
              return { "fd", "-tf", "-td", "-d", "4", "--color", "never" }
            end,
          }),
          desc = "[S]elect in neovim plugin files",
        },
        {
          "<leader>spg",
          Builtin.live_grep({
            cwd = "~/.local/share/nvim/lazy",
            prompt_title = "[S]earch inside neovim plugins by [g]rep",
          }),
          desc = "[S]earch nix [s]storesgby [g]rep",
        },
        {
          "<leader>sw",
          function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ cwd = vim.fn.getcwd(), search = word, prompt_title = word })
          end,
          desc = "[S]earch current [w]ord",
        },
        {
          "<leader>sW",
          function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ cwd = vim.fn.getcwd(), search = word, prompt_title = word })
          end,
          desc = "[S]earch current namespaced [W]ord",
        },
        { "<leader>s.", builtin.oldfiles, desc = '[S]earch recent files ("." for repeat)' },
        -- {
        --   "<leader>sbf",
        --   function()
        --     builtin.buffers({
        --       bufnr_width = 3,
        --       sort_buffers = false,
        --     })
        --     -- pickers
        --     --   .new(opts, {
        --     --     prompt_title = "Buffers",
        --     --     finder = finders.new_table {
        --     --       results = buffers,
        --     --       entry_maker = opts.entry_maker or make_entry.gen_from_buffer(opts),
        --     --     },
        --     --     previewer = conf.grep_previewer(opts),
        --     --     sorter = conf.generic_sorter(opts),
        --     --     default_selection_index = default_selection_idx,
        --     --   })
        --     --   :find()
        --   end,
        --   desc = "[] Select buffer",
        -- },
        {
          "<leader>sbg",
          Builtin.live_grep({
            grep_open_files = true,
            prompt_title = "[S]earch existing buffers by [g]rep",
          }),
          desc = "[S]earch existing buffers by [g]rep",
        },
        {
          "<leader>scf",
          Builtin.find_files({ cwd = vim.fn.stdpath("config") }),
          desc = "[S]elect nvim [c]onfig [f]iles",
        },
        {
          "<leader>scg",
          Builtin.live_grep({
            cwd = vim.fn.stdpath("config"),
            prompt_title = "[S]earch [n]vim [c]onfig by [g]rep",
          }),
          desc = "[S]earch [n]vim [c]onfig by [g]rep",
        },
        {
          "<leader>sn",
          function()
            vim.cmd.Telescope("notify")
          end,
          desc = "[S]earch [n]otification history",
        },
        { "<leader>st", builtin.builtin, desc = "[S]earch [t]elescope Builtins" },
        { "<leader>sd", builtin.diagnostics, desc = "[S]earch [d]iagnostics" }, -- NOTE: Check to see if this can be useful
        { "<leader>sR", builtin.resume, desc = "[S]elect & [r]esume last builtin" },

        -- TODO: Add LSP stuff
        -- TODO: Add register
        -- TODO: Add marks

        {
          "<C-b>",
          Builtin.bufferline(),
          mode = { "v", "i", "n" },
          desc = "[S]elect [b]uffer",
        },
        {
          "<C-f>",
          Builtin.find_files({}),
          mode = { "v", "i", "n" },
          desc = "[S]earch project [f]iles",
        },
        {
          "<C-g>",
          Builtin.live_grep({
            cwd = vim.fn.getcwd(),
            prompt_title = "[S]earch project files by [g]rep",
          }),
          mode = { "v", "i", "n" },
          desc = "[S]earch project files by [g]rep",
        },
      })
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          layout_strategy = "horizontal",
          selection_strategy = "follow", -- For each sort iteration : "reset" | "folow" | "row" | "closest" | "none"
          scroll_strategy = "cycle", -- "cycle" | "limit"
          sorting_strategy = "ascending", -- Default: descending
          layout_config = {
            bottom_pane = {
              prompt_position = "top",
              height = 25,
              preview_cutoff = 120,
            },
            center = {
              prompt_position = "top",
              height = 0.4,
              width = 0.5,
              preview_cutoff = 40,
            },
            cursor = {
              height = 0.9,
              width = 0.8,
              preview_cutoff = 40,
            },
            horizontal = {
              prompt_position = "top",
              height = 0.9,
              width = 0.8,
              preview_cutoff = 120,
            },
            vertical = {
              prompt_position = "top",
              height = 0.9,
              width = 0.8,
              preview_cutoff = 40,
            },
          },
          cycle_layout_list = { "horizontal", "vertical" }, -- For: actions.layout.cycle_layout_next | can be string(from layout_strategy) or { layout_stategy, layout_config, previewer }
          winblend = 10,
          wrap_results = false,
          prompt_prefix = "> ",
          selection_caret = "> ",
          entry_prefix = "  ",
          multi_icon = "+", -- For: multi-selection
          initial_mode = "insert", -- For: could be normal or insert
          border = true,

          -- NOTE: This slows it down significantly
          -- path_display = { shorten = { len = 5, exclude = { 1, -1, -2 } } }, -- Accepts: "hidden", "tail", "absolute", "smart", "truncate" (3), shorten", or function(opts, path)
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          -- get_status_text = "current_count / all",
          hl_result_eol = true, -- Changes if the highlight for the selected item on full width
          dynamic_preview_title = false,
          results_title = "Results",
          prompt_title = "Prompt",
          mappings = {
            i = {
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,

              ["<C-z><C-z>"] = actions.move_to_top,
              ["<C-z>"] = actions.move_to_bottom,

              ["<C-s>"] = actions.select_vertical,
              ["<C-e>"] = actions.select_default,
              ["<C-o>"] = function(prompt_bufnr)
                local utils = require("telescope.utils")
                local selected_path = action_state.get_selected_entry()[1]
                local file_type_stdout = utils.get_os_command_output({
                  "xdg-mime",
                  "query",
                  "filetype",
                  selected_path,
                })[1]
                local default_application_stdout = utils.get_os_command_output({
                  "xdg-mime",
                  "query",
                  "default",
                  file_type_stdout,
                })[1]

                if default_application_stdout and string.len(default_application_stdout) > 0 then
                  utils.get_os_command_output({ "xdg-open", selected_path })

                  return actions.close(prompt_bufnr)
                end

                return actions.select_default(prompt_bufnr)
              end,

              ["<C-y><C-y>"] = function(prompt_bufnr)
                local selected_entries = {}
                local picker = action_state.get_current_picker(prompt_bufnr)
                for _, entry in ipairs(picker:get_multi_selection()) do
                  table.insert(selected_entries, entry.value)
                end

                local final_text = table.concat(selected_entries, "\n")

                vim.fn.setreg("+", final_text)
                vim.fn.setreg('"', final_text)
              end,
              ["<C-y><C-i>"] = function(prompt_bufnr)
                local selected_entries = {}
                local picker = action_state.get_current_picker(prompt_bufnr)
                for _, entry in ipairs(picker:get_multi_selection()) do
                  table.insert(selected_entries, entry.value)
                end

                actions.close(prompt_bufnr)
                vim.api.nvim_feedkeys("j", "n", false)
                vim.schedule(function()
                  vim.api.nvim_put(selected_entries, "", true, true)
                end)
              end,

              ["<C-a>"] = actions.toggle_all, -- TODO: Make this select_all or drop_all
              ["<C-space>"] = actions.toggle_selection,

              ["<C-m>"] = actions.preview_scrolling_down,
              ["<C-h>"] = actions.preview_scrolling_up,
              -- NOTE: Not available yet on v0.1.8
              -- ["<C-[>"] = actions.preview_scrolling_left, -- Alternative is C-<
              -- ["<C-]>"] = actions.preview_scrolling_right, -- Alternative is C->

              ["<C-/>"] = actions.which_key,
              ["<C-c>"] = actions.close,

              -- ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              -- ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-Del>"] = builtin.resume,
              ["<C-f>"] = Builtin.find_files({
                no_ignore = true,
                no_ignore_parent = true,
              }),
            },
            n = {
              ["j"] = actions.cycle_history_next,
              ["k"] = actions.cycle_history_prev,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,

              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,

              ["g"] = actions.move_to_top,
              ["G"] = actions.move_to_bottom,
              ["<C-z>"] = actions.move_to_bottom,

              ["<C-s>"] = actions.select_vertical,
              ["<C-e>"] = actions.select_default,
              ["<C-o>"] = function(prompt_bufnr)
                local Job = require("plenary.job")
                local selected_path = action_state.get_selected_entry()[1]

                local file_type_stdout = Job:new({
                  command = "xdg-mime",
                  args = { "query", "filetype", selected_path },
                })
                  :sync()[1]
                local default_application_stdout = Job:new({
                  command = "xdg-mime",
                  args = { "query", "default", file_type_stdout },
                })
                  :sync()[1]

                if default_application_stdout and string.len(default_application_stdout) > 0 then
                  Job:new({
                    command = "xdg-open",
                    args = { selected_path },
                  }):sync()

                  return actions.close(prompt_bufnr)
                end

                return actions.select_default(prompt_bufnr)
              end,

              ["<C-y><C-y>"] = function(prompt_bufnr)
                local selected_entries = {}
                local picker = action_state.get_current_picker(prompt_bufnr)
                for _, entry in ipairs(picker:get_multi_selection()) do
                  table.insert(selected_entries, entry.value)
                end

                local final_text = table.concat(selected_entries, "\n")

                vim.fn.setreg("+", final_text)
                vim.fn.setreg('"', final_text)
              end,
              ["<C-y><C-i>"] = function(prompt_bufnr)
                local selected_entries = {}
                local picker = action_state.get_current_picker(prompt_bufnr)
                for _, entry in ipairs(picker:get_multi_selection()) do
                  table.insert(selected_entries, entry.value) -- TODO: sometimes entry[1] is NOT String
                end
                actions.close(prompt_bufnr)
                vim.api.nvim_feedkeys("j", "n", false)
                vim.schedule(function()
                  vim.api.nvim_put(selected_entries, "", true, true) -- TODO: is this correct method? or another way to add(?)
                end)
              end,

              ["<C-a>"] = actions.toggle_all, -- TODO: Make this select_all or drop_all
              ["<C-space>"] = actions.toggle_selection,

              ["<C-m>"] = actions.preview_scrolling_down,
              ["<C-h>"] = actions.preview_scrolling_up,
              -- NOTE: Not available yet on v0.1.8
              -- ["<C-[>"] = actions.preview_scrolling_left, -- Alternative is C-<
              -- ["<C-]>"] = actions.preview_scrolling_right, -- Alternative is C->

              ["<C-/>"] = actions.which_key,
              ["<C-c>"] = actions.close,

              -- ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              -- ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-Del>"] = builtin.resume,
              ["<C-f>"] = Builtin.find_files({
                no_ignore = true,
                no_ignore_parent = true,
              }),
            },
          },
          -- history = { path = "", limit = 100, handler: require('telescope.actions.history').get_simple_history }
          cache_picker = { num_pickers = 1, limit_entries = 1000 }, -- -1 preserves all pickers,
          preview = {
            check_mime_type = true,
            filesize_limit = 25,
            timeout = 250,
            treesitter = true, -- Also accepts a { enable , disable } table
            msg_bg_fillchar = "╱",
            hide_on_startup = false, -- To toggle in lua: actions.layout.toggle_preview
          }, -- Also has: { filetype_hook, filesize_hook(!!), hooks = { function(filepath, bufnr, opts) end } }
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          }, -- For live_grep & grep_string
          set_env = nil,
          color_devicons = true,
          -- file_sorter = require("telescope.sorters").get_fzy_sorter, -- For: builtin find_files, git_files and similar
          -- generic_sorter = require("telescope.sorters").get_fzy_sorter, -- For anything that is not a file
          -- prefilter_sorter = require("telescope.sorters").prefilter, -- For: prefiltering usually for lsp_*_symbols lsp_*_diagnostics
          -- tiebreak = function(current_entry, existing_entry, prompt) -> boolean -- For: sorting on tie
          file_ignore_patterns = nil, -- Example: { "^scratch/", "%.npz" } -- ignore all files in scratch directory, ignore all npz files, runs on *all* builtin incl lsps
          -- get_selection_window = function(picker, entry) return 0 end -- return is an expected window id to load the buffer
          file_previewer = require("telescope.previewers").vim_buffer_cat.new, -- Mostly in find_files, git_files
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new, -- For live_grep, grep_string builtins
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new, -- For qflist, loclist & lsp builtins
          buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker, -- Samples: https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes
          -- use_less = true | Deprecated, not used in builtin pickers
        },
        pickers = {}, -- NOTE: From LazyVim, does this still exist(?)
        extensions = {
          -- NOTE: wrap_results

          -- fzf = {},
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      telescope.load_extension("fzf")
      -- telescope.load_extension("ui-select")
    end,
  },
}

-- TODO: Check these plugins:
--   {
--     "nvim-telescope/telescope-file-browser.nvim",
--     dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
--   },
-- TODO: Add https://github.com/nvim-telescope/telescope-media-files.nvim AND OPEN.
-- Maybe: https://github.com/tamago324/telescope-openbrowser.nvim
-- Maybe: https://github.com/nvim-neorg/neorg-telescope

-- { "<leader>/", function()
--   -- NOTE: Example advanced builtin. You can pass additional configuration to Telescope to change the theme, layout, etc.
--   builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
--     winblend = 10, -- NOTE: This adds opacity
--     previewer = false,
--   }))
-- end, desc = "[/] Fuzzily search in current buffer" }
-- local action_set = require("telescope.actions.set")

-- local append_to_history = function(prompt_bufnr)
--   action_state
--     .get_current_history()
--     :append(action_state.get_current_line(), action_state.get_current_picker(prompt_bufnr))
-- end
--
-- Extensions to consider:
-- octo.nvim(maybe also nvim-telescope/telescope-github.nvim)
-- Media files: https://github.com/nvim-telescope/telescope-media-files.nvim
-- Browser bookmarks: https://github.com/dhruvmanila/browser-bookmarks.nvim
-- Search Emoji: https://github.com/xiyaowong/telescope-emoji.nvim
-- Run individual test with: https://github.com/sshelll/telescope-gott.nvim?tab=readme-ov-file
-- Neoclip: https://github.com/AckslD/nvim-neoclip.lua
-- Gitmoji: https://github.com/olacin/telescope-gitmoji.nvim?tab=readme-ov-file
-- Show ports and kill them: https://github.com/LinArcX/telescope-ports.nvim
-- Manix: https://github.com/MrcJkb/telescope-manix
-- Undo list: https://github.com/debugloop/telescope-undo.nvim
-- Help frep: https://github.com/catgoose/telescope-helpgrep.nvim
-- DAP: https://github.com/nvim-telescope/telescope-dap.nvim
-- Neorg: https://github.com/nvim-neorg/neorg-telescope
-- Toggleterm: https://github.com/ryanmsnyder/toggleterm-manager.nvim
