-- TODO: Learn customizing Edgy windows
-- https://huggingface.co/spaces/mike-ravkine/can-ai-code-results
-- Check also https://github.com/olimorris/codecompanion.nvim
-- https://github.com/you-n-g/simplegpt.nvim
-- Interesting preview: https://github.com/HPRIOR/telescope-gpt

-- <space>Ae - explain
-- <space>Ar - refactor
-- <space>At - test
-- <space>Ad - document
-- <space>Ap - prompt(get selected area, yanked area, filesystem add)
-- <space>Ac - chat
-- <space>Ah - history
-- <space>As - sessions
-- <space>Ai - insert mode - AI | yada Ag generate
-- <space>Am - model select Or run
-- <space>AM - create model and then create chat with it

-- also check: https://github.com/gerazov/ollama-chat.nvim
return {
  {
    "Exafunction/codeium.nvim",
    cmd = "Codeium",
    build = ":Codeium Auth",
    opts = {
      enable_chat = true,
    },
  },
  {
    "nomnivore/ollama.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    -- All the user commands added by the plugin
    cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

    keys = {
      -- Sample keybind for prompt menu. Note that the <c-u> is important for selections to work properly.
      {
        "<leader>oo",
        ":<c-u>lua require('ollama').prompt()<cr>",
        desc = "ollama prompt",
        mode = { "n", "v" },
      },

      -- Sample keybind for direct prompting. Note that the <c-u> is important for selections to work properly.
      {
        "<leader>oG",
        ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
        desc = "ollama Generate Code",
        mode = { "n", "v" },
      },
    },

    ---@type Ollama.Config
    opts = {
      -- your configuration overrides
    },
  },
  -- https://github.com/nomnivore/ollama.nvim -> This gets ollama stuff correctly, implement oatmeal /modellist, /c 3, treesitter, chat history list/view, vim movements, inteference interrupt
  -- lualine AI working
  {
    "Robitx/gp.nvim",
    -- opts = {
    --   openai_api_key = { "pass", "show", "Identity/api/openai" },
    --   openai_api_endpoint = "https://127.0.0.1:11434/v1/chat/completions",
    --     cmd_prefix = "Gp",
    --     curl_params = { "--proxy", "http://X.X.X.X:XXXX" }
    --
    --     -- directory for persisting state dynamically changed by user (like model or persona)
    --     state_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/gp/persisted",
    --
    --     -- default command agents (model + persona)
    --     -- name, model and system_prompt are mandatory fields
    --     -- to use agent for chat set chat = true, for command set command = true
    --     -- to remove some default agent completely set it just with the name like:
    --     -- agents = {  { name = "ChatGPT4" }, ... },
    --     agents = {
    --       {
    --         name = "ChatGPT4",
    --         chat = true,
    --         command = false,
    --         -- string with model name or table with model name and parameters
    --         model = { model = "gpt-4-1106-preview", temperature = 1.1, top_p = 1 },
    --         -- system prompt (use this to specify the persona/role of the AI)
    --         system_prompt = "You are a general AI assistant.\n\n"
    --           .. "The user provided the additional info about how they would like you to respond:\n\n"
    --           .. "- If you're unsure don't guess and say you don't know instead.\n"
    --           .. "- Ask question if you need clarification to provide better answer.\n"
    --           .. "- Think deeply and carefully from first principles step by step.\n"
    --           .. "- Zoom out first to see the big picture and then zoom in to details.\n"
    --           .. "- Use Socratic method to improve your thinking and coding skills.\n"
    --           .. "- Don't elide any code from your output if the answer requires coding.\n"
    --           .. "- Take a deep breath; You've got this!\n",
    --       },
    --       {
    --         name = "ChatGPT3-5",
    --         chat = true,
    --         command = false,
    --         -- string with model name or table with model name and parameters
    --         model = { model = "gpt-3.5-turbo-1106", temperature = 1.1, top_p = 1 },
    --         -- system prompt (use this to specify the persona/role of the AI)
    --         system_prompt = "You are a general AI assistant.\n\n"
    --           .. "The user provided the additional info about how they would like you to respond:\n\n"
    --           .. "- If you're unsure don't guess and say you don't know instead.\n"
    --           .. "- Ask question if you need clarification to provide better answer.\n"
    --           .. "- Think deeply and carefully from first principles step by step.\n"
    --           .. "- Zoom out first to see the big picture and then zoom in to details.\n"
    --           .. "- Use Socratic method to improve your thinking and coding skills.\n"
    --           .. "- Don't elide any code from your output if the answer requires coding.\n"
    --           .. "- Take a deep breath; You've got this!\n",
    --       },
    --       {
    --         name = "CodeGPT4",
    --         chat = false,
    --         command = true,
    --         -- string with model name or table with model name and parameters
    --         model = { model = "gpt-4-1106-preview", temperature = 0.8, top_p = 1 },
    --         -- system prompt (use this to specify the persona/role of the AI)
    --         system_prompt = "You are an AI working as a code editor.\n\n"
    --           .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
    --           .. "START AND END YOUR ANSWER WITH:\n\n```",
    --       },
    --       {
    --         name = "CodeGPT3-5",
    --         chat = false,
    --         command = true,
    --         -- string with model name or table with model name and parameters
    --         model = { model = "gpt-3.5-turbo-1106", temperature = 0.8, top_p = 1 },
    --         -- system prompt (use this to specify the persona/role of the AI)
    --         system_prompt = "You are an AI working as a code editor.\n\n"
    --           .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
    --           .. "START AND END YOUR ANSWER WITH:\n\n```",
    --       },
    --     },
    --
    --     -- directory for storing chat files
    --     chat_dir = vim.fn.stdpath("data"):gsub("/$", "") .. "/gp/chats",
    --     -- chat user prompt prefix
    --     chat_user_prefix = "🗨:",
    --     -- chat assistant prompt prefix (static string or a table {static, template})
    --     -- first string has to be static, second string can contain template {{agent}}
    --     -- just a static string is legacy and the [{{agent}}] element is added automatically
    --     -- if you really want just a static string, make it a table with one element { "🤖:" }
    --     chat_assistant_prefix = { "🤖:", "[{{agent}}]" },
    --     -- chat topic generation prompt
    --     chat_topic_gen_prompt = "Summarize the topic of our conversation above"
    --       .. " in two or three words. Respond only with those words.",
    --     -- chat topic model (string with model name or table with model name and parameters)
    --     chat_topic_gen_model = "gpt-3.5-turbo-16k",
    --     -- explicitly confirm deletion of a chat file
    --     chat_confirm_delete = true,
    --     -- conceal model parameters in chat
    --     chat_conceal_model_params = true,
    --     -- local shortcuts bound to the chat buffer
    --     -- (be careful to choose something which will work across specified modes)
    --     chat_shortcut_respond = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g><C-g>" },
    --     chat_shortcut_delete = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>d" },
    --     chat_shortcut_stop = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>s" },
    --     chat_shortcut_new = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>c" },
    --     -- default search term when using :GpChatFinder
    --     chat_finder_pattern = "topic ",
    --     -- if true, finished ChatResponder won't move the cursor to the end of the buffer
    --     chat_free_cursor = false,
    --
    --     -- how to display GpChatToggle or GpContext: popup / split / vsplit / tabnew
    --     toggle_target = "vsplit",
    --
    --     -- styling for chatfinder
    --     -- border can be "single", "double", "rounded", "solid", "shadow", "none"
    --     style_chat_finder_border = "single",
    --     -- margins are number of characters or lines
    --     style_chat_finder_margin_bottom = 8,
    --     style_chat_finder_margin_left = 1,
    --     style_chat_finder_margin_right = 2,
    --     style_chat_finder_margin_top = 2,
    --     -- how wide should the preview be, number between 0.0 and 1.0
    --     style_chat_finder_preview_ratio = 0.5,
    --
    --     -- styling for popup
    --     -- border can be "single", "double", "rounded", "solid", "shadow", "none"
    --     style_popup_border = "single",
    --     -- margins are number of characters or lines
    --     style_popup_margin_bottom = 8,
    --     style_popup_margin_left = 1,
    --     style_popup_margin_right = 2,
    --     style_popup_margin_top = 2,
    --     style_popup_max_width = 160,
    --
    --     -- command config and templates bellow are used by commands like GpRewrite, GpEnew, etc.
    --     -- command prompt prefix for asking user for input (supports {{agent}} template variable)
    --     command_prompt_prefix_template = "🤖 {{agent}} ~ ",
    --     -- auto select command response (easier chaining of commands)
    --     -- if false it also frees up the buffer cursor for further editing elsewhere
    --     command_auto_select_response = true,
    --
    --     -- templates
    --     template_selection = "I have the following from {{filename}}:"
    --       .. "\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}",
    --     template_rewrite = "I have the following from {{filename}}:"
    --       .. "\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}"
    --       .. "\n\nRespond exclusively with the snippet that should replace the selection above.",
    --     template_append = "I have the following from {{filename}}:"
    --       .. "\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}"
    --       .. "\n\nRespond exclusively with the snippet that should be appended after the selection above.",
    --     template_prepend = "I have the following from {{filename}}:"
    --       .. "\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}"
    --       .. "\n\nRespond exclusively with the snippet that should be prepended before the selection above.",
    --     template_command = "{{command}}",
    --
    --     -- https://platform.openai.com/docs/guides/speech-to-text/quickstart
    --     -- Whisper costs $0.006 / minute (rounded to the nearest second)
    --     -- by eliminating silence and speeding up the tempo of the recording
    --     -- we can reduce the cost by 50% or more and get the results faster
    --     -- directory for storing whisper files
    --     whisper_dir = (os.getenv("TMPDIR") or os.getenv("TEMP") or "/tmp") .. "/gp_whisper",
    --     -- multiplier of RMS level dB for threshold used by sox to detect silence vs speech
    --     -- decibels are negative, the recording is normalized to -3dB =>
    --     -- increase this number to pick up more (weaker) sounds as possible speech
    --     -- decrease this number to pick up only louder sounds as possible speech
    --     -- you can disable silence trimming by setting this a very high number (like 1000.0)
    --     whisper_silence = "1.75",
    --     -- whisper max recording time (mm:ss)
    --     whisper_max_time = "05:00",
    --     -- whisper tempo (1.0 is normal speed)
    --     whisper_tempo = "1.75",
    --     -- The language of the input audio, in ISO-639-1 format.
    --     whisper_language = "en",
    --
    --     -- image generation settings
    --     -- image prompt prefix for asking user for input (supports {{agent}} template variable)
    --     image_prompt_prefix_template = "🖌️ {{agent}} ~ ",
    --     -- image prompt prefix for asking location to save the image
    --     image_prompt_save = "🖌️💾 ~ ",
    --     -- default folder for saving images
    --     image_dir = (os.getenv("TMPDIR") or os.getenv("TEMP") or "/tmp") .. "/gp_images",
    --     -- default image agents (model + settings)
    --     -- to remove some default agent completely set it just with the name like:
    --     -- image_agents = {  { name = "DALL-E-3-1024x1792-vivid" }, ... },
    --     image_agents = {
    --       {
    --         name = "DALL-E-3-1024x1024-vivid",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "vivid",
    --         size = "1024x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1792x1024-vivid",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "vivid",
    --         size = "1792x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1792-vivid",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "vivid",
    --         size = "1024x1792",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1024-natural",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "natural",
    --         size = "1024x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1792x1024-natural",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "natural",
    --         size = "1792x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1792-natural",
    --         model = "dall-e-3",
    --         quality = "standard",
    --         style = "natural",
    --         size = "1024x1792",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1024-vivid-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "vivid",
    --         size = "1024x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1792x1024-vivid-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "vivid",
    --         size = "1792x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1792-vivid-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "vivid",
    --         size = "1024x1792",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1024-natural-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "natural",
    --         size = "1024x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1792x1024-natural-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "natural",
    --         size = "1792x1024",
    --       },
    --       {
    --         name = "DALL-E-3-1024x1792-natural-hd",
    --         model = "dall-e-3",
    --         quality = "hd",
    --         style = "natural",
    --         size = "1024x1792",
    --       },
    --     },
    --
    --     -- example hook functions (see Extend functionality section in the README)
    --     hooks = {
    --       InspectPlugin = function(plugin, params)
    --         local bufnr = vim.api.nvim_create_buf(false, true)
    --         local copy = vim.deepcopy(plugin)
    --         local key = copy.config.openai_api_key
    --         copy.config.openai_api_key = key:sub(1, 3) .. string.rep("*", #key - 6) .. key:sub(-3)
    --         local plugin_info = string.format("Plugin structure:\n%s", vim.inspect(copy))
    --         local params_info = string.format("Command params:\n%s", vim.inspect(params))
    --         local lines = vim.split(plugin_info .. "\n" .. params_info, "\n")
    --         vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    --         vim.api.nvim_win_set_buf(0, bufnr)
    --       end,
    --
    --       -- GpImplement rewrites the provided selection/range based on comments in it
    --       Implement = function(gp, params)
    --         local template = "Having following from {{filename}}:\n\n"
    --           .. "```{{filetype}}\n{{selection}}\n```\n\n"
    --           .. "Please rewrite this according to the contained instructions."
    --           .. "\n\nRespond exclusively with the snippet that should replace the selection above."
    --
    --         local agent = gp.get_command_agent()
    --         gp.info("Implementing selection with agent: " .. agent.name)
    --
    --         gp.Prompt(
    --           params,
    --           gp.Target.rewrite,
    --           nil, -- command will run directly without any prompting for user input
    --           agent.model,
    --           template,
    --           agent.system_prompt
    --         )
    --       end,
    --
    --       -- your own functions can go here, see README for more examples like
    --       -- :GpExplain, :GpUnitTests.., :GpTranslator etc.
    --
    --       -- -- example of making :%GpChatNew a dedicated command which
    --       -- -- opens new chat with the entire current buffer as a context
    --       -- BufferChatNew = function(gp, _)
    --       -- 	-- call GpChatNew command in range mode on whole buffer
    --       -- 	vim.api.nvim_command("%" .. gp.config.cmd_prefix .. "ChatNew")
    --       -- end,
    --
    --       -- -- example of adding command which opens new chat dedicated for translation
    --       -- Translator = function(gp, params)
    --       -- 	local agent = gp.get_command_agent()
    --       -- 	local chat_system_prompt = "You are a Translator, please translate between English and Chinese."
    --       -- 	gp.cmd.ChatNew(params, agent.model, chat_system_prompt)
    --       -- end,
    --
    --       -- -- example of adding command which writes unit tests for the selected code
    --       -- UnitTests = function(gp, params)
    --       -- 	local template = "I have the following code from {{filename}}:\n\n"
    --       -- 		.. "```{{filetype}}\n{{selection}}\n```\n\n"
    --       -- 		.. "Please respond by writing table driven unit tests for the code above."
    --       -- 	local agent = gp.get_command_agent()
    --       -- 	gp.Prompt(params, gp.Target.enew, nil, agent.model, template, agent.system_prompt)
    --       -- end,
    --
    --       -- -- example of adding command which explains the selected code
    --       -- Explain = function(gp, params)
    --       -- 	local template = "I have the following code from {{filename}}:\n\n"
    --       -- 		.. "```{{filetype}}\n{{selection}}\n```\n\n"
    --       -- 		.. "Please respond by explaining the code above."
    --       -- 	local agent = gp.get_chat_agent()
    --       -- 	gp.Prompt(params, gp.Target.popup, nil, agent.model, template, agent.system_prompt)
    --       -- end,
    --     },
    --   },
    -- },
    -- {
    --   "David-Kunz/gen.nvim",
    --   opts = {
    --     model = "llama3", -- The default model to use.
    --     host = "localhost", -- The host running the Ollama service.
    --     port = "11434", -- The port on which the Ollama service is listening.
    --     quit_map = "q", -- set keymap for close the response window
    --     retry_map = "<c-r>", -- set keymap to re-send the current prompt
    --     init = function(options)
    --       pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
    --     end,
    --     -- Function to initialize Ollama
    --     command = function(options)
    --       local body = { model = options.model, stream = true }
    --       return "curl --silent --no-buffer -X POST http://"
    --         .. options.host
    --         .. ":"
    --         .. options.port
    --         .. "/api/chat -d $body"
    --     end,
    --     -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
    --     -- This can also be a command string.
    --     -- The executed command must return a JSON object with { response, context }
    --     -- (context property is optional).
    --     -- list_models = '<omitted lua function>', -- Retrieves a list of model names
    --     display_mode = "float", -- The display mode. Can be "float" or "split".
    --     show_prompt = false, -- Shows the prompt submitted to Ollama.
    --     show_model = true, -- Displays which model you are using at the beginning of your chat session.
    --     no_auto_close = false, -- Never closes the window automatically.
    --     debug = false, -- Prints errors and the command which is run.
    --   },
    -- },
    -- {
    --   "jackMort/ChatGPT.nvim",
    --   event = "VeryLazy",
    --   dependencies = {
    --     "MunifTanjim/nui.nvim",
    --     "nvim-lua/plenary.nvim",
    --     "folke/trouble.nvim",
    --     "nvim-telescope/telescope.nvim",
    --   },
    --   config = function()
    --     require("chatgpt").setup({
    --       api_key_cmd = "pass show Identity/api/openai",
    --       yank_register = "+",
    --       edit_with_instructions = {
    --         diff = false,
    --         keymaps = {
    --           close = "<C-c>",
    --           accept = "<C-y>",
    --           toggle_diff = "<C-d>",
    --           toggle_settings = "<C-o>",
    --           toggle_help = "<C-h>",
    --           cycle_windows = "<Tab>",
    --           use_output_as_input = "<C-i>",
    --         },
    --       },
    --       chat = {
    --         welcome_message = "Izels welcome message",
    --         loading_text = "Loading, please wait ...",
    --         question_sign = "", -- 🙂
    --         answer_sign = "ﮧ", -- 🤖
    --         border_left_sign = "",
    --         border_right_sign = "",
    --         max_line_length = 120,
    --         sessions_window = {
    --           active_sign = "  ",
    --           inactive_sign = "  ",
    --           current_line_sign = "",
    --           border = {
    --             style = "rounded",
    --             text = {
    --               top = " Sessions ",
    --             },
    --           },
    --           win_options = {
    --             winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --           },
    --         },
    --         keymaps = {
    --           close = "<C-c>",
    --           yank_last = "<C-y>",
    --           yank_last_code = "<C-k>",
    --           scroll_up = "<C-u>",
    --           scroll_down = "<C-d>",
    --           new_session = "<C-n>",
    --           cycle_windows = "<Tab>",
    --           cycle_modes = "<C-f>",
    --           next_message = "<C-j>",
    --           prev_message = "<C-k>",
    --           select_session = "<Space>",
    --           rename_session = "r",
    --           delete_session = "d",
    --           draft_message = "<C-r>",
    --           edit_message = "e",
    --           delete_message = "d",
    --           toggle_settings = "<C-o>",
    --           toggle_sessions = "<C-p>",
    --           toggle_help = "<C-h>",
    --           toggle_message_role = "<C-r>",
    --           toggle_system_role_open = "<C-s>",
    --           stop_generating = "<C-x>",
    --         },
    --       },
    --       popup_layout = {
    --         default = "center",
    --         center = {
    --           width = "80%",
    --           height = "80%",
    --         },
    --         right = {
    --           width = "30%",
    --           width_settings_open = "50%",
    --         },
    --       },
    --       popup_window = {
    --         border = {
    --           highlight = "FloatBorder",
    --           style = "rounded",
    --           text = {
    --             top = " ChatGPT ",
    --           },
    --         },
    --         win_options = {
    --           wrap = true,
    --           linebreak = true,
    --           foldcolumn = "1",
    --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --         },
    --         buf_options = {
    --           filetype = "markdown",
    --         },
    --       },
    --       system_window = {
    --         border = {
    --           highlight = "FloatBorder",
    --           style = "rounded",
    --           text = {
    --             top = " SYSTEM ",
    --           },
    --         },
    --         win_options = {
    --           wrap = true,
    --           linebreak = true,
    --           foldcolumn = "2",
    --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --         },
    --       },
    --       popup_input = {
    --         prompt = "  ",
    --         border = {
    --           highlight = "FloatBorder",
    --           style = "rounded",
    --           text = {
    --             top_align = "center",
    --             top = " Prompt ",
    --           },
    --         },
    --         win_options = {
    --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --         },
    --         submit = "<C-Enter>",
    --         submit_n = "<Enter>",
    --         max_visible_lines = 20,
    --       },
    --       settings_window = {
    --         setting_sign = "  ",
    --         border = {
    --           style = "rounded",
    --           text = {
    --             top = " Settings ",
    --           },
    --         },
    --         win_options = {
    --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --         },
    --       },
    --       help_window = {
    --         setting_sign = "  ",
    --         border = {
    --           style = "rounded",
    --           text = {
    --             top = " Help ",
    --           },
    --         },
    --         win_options = {
    --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    --         },
    --       },
    --       api_host_cmd = "echo http://localhost:11434",
    --       api_key_cmd = "echo ''",
    --       openai_params = {
    --         model = "gpt-3.5-turbo", -- OR: "llama3:latest",
    --         frequency_penalty = 0,
    --         presence_penalty = 0,
    --         max_tokens = 300,
    --         temperature = 0,
    --         top_p = 1,
    --         n = 1,
    --       },
    --       openai_edit_params = {
    --         model = "gpt-3.5-turbo", -- OR: "llama3:latest",
    --         frequency_penalty = 0,
    --         presence_penalty = 0,
    --         temperature = 0,
    --         top_p = 1,
    --         n = 1,
    --       },
    --       use_openai_functions_for_edits = false,
    --       actions_paths = {},
    --       show_quickfixes_cmd = "Trouble quickfix",
    --       predefined_chat_gpt_prompts = "https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv",
    --       highlights = {
    --         help_key = "@symbol",
    --         help_description = "@comment",
    --       },
    --     })
    --   end,
  },
}
