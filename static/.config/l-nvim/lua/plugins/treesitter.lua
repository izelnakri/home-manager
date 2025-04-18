-- TODO:implement this for space movements esp for markdown
-- frame.inner, cell.inner, statement.outer, customCapture
-- inner.paragraph, outer.paragraph, inner.section, outer.section
-- How to view text objects?!

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.textobjects = {
        lsp_interop = {
          enable = true,
          -- border = "none",
          floating_preview_opts = {},
          peek_definition_code = {
            ["<leader>df"] = "@function.outer",
            ["<leader>dF"] = "@class.outer",
          },
        },
        select = {
          enable = true,

          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,

          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
            ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
            ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

            -- works for javascript/typescript files (custom capture I created in after/queries/ecma/textobjects.scm)
            ["a:"] = { query = "@property.outer", desc = "Select outer part of an object property" },
            ["i:"] = { query = "@property.inner", desc = "Select inner part of an object property" },
            ["r:"] = { query = "@property.rhs", desc = "Select right part of an object property" },

            ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
            ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

            ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
            ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

            ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
            ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

            ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
            ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

            ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
            ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

            ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
            ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>na"] = "@parameter.inner", -- swap parameters/argument with next
            ["<leader>n:"] = "@property.outer", -- swap object property with next
            ["<leader>nm"] = "@function.outer", -- swap function with next
          },
          swap_previous = {
            ["<leader>pa"] = "@parameter.inner", -- swap parameters/argument with prev
            ["<leader>p:"] = "@property.outer", -- swap object property with prev
            ["<leader>pm"] = "@function.outer", -- swap function with previous
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]b"] = { query = "@block.outer", desc = "Next block" },

            ["]="] = { query = "@assignment.outer", desc = "Next assignment" },
            ["]:"] = { query = "@property.outer", desc = "Next object property" },

            ["]a"] = { query = "@parameter.outer", desc = "Next parameter/argument start" },
            ["]f"] = { query = "@call.outer", desc = "Next function call start" },
            ["]m"] = { query = "@function.outer", desc = "Next method/function def start" },

            ["]c"] = { query = "@class.outer", desc = "Next class start" },

            ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
            ["]l"] = { query = "@loop.outer", desc = "Next loop start" },
            -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
            -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
            ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
            -- ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_next_end = {
            ["]F"] = { query = "@call.outer", desc = "Next function call end" },
            ["]M"] = { query = "@function.outer", desc = "Next method/function def end" },
            ["]C"] = { query = "@class.outer", desc = "Next class end" },
            ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
            ["]L"] = { query = "@loop.outer", desc = "Next loop end" },
          },
          goto_previous_start = {
            ["[b"] = { query = "@block.outer", desc = "Next block" },

            ["[="] = { query = "@assignment.outer", desc = "Next assignment" },
            ["[:"] = { query = "@property.outer", desc = "Next object property" },

            ["[a"] = { query = "@parameter.outer", desc = "Next parameter/argument start" },
            ["[f"] = { query = "@call.outer", desc = "Prev function call start" },
            ["[m"] = { query = "@function.outer", desc = "Prev method/function def start" },

            ["[c"] = { query = "@class.outer", desc = "Prev class start" },

            ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
            ["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
          },
          goto_previous_end = {
            ["[F"] = { query = "@call.outer", desc = "Prev function call end" },
            ["[M"] = { query = "@function.outer", desc = "Prev method/function def end" },
            ["[C"] = { query = "@class.outer", desc = "Prev class end" },
            ["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
            ["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
          },
        },
      }

      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

      -- vim way: ; goes to the direction you were moving.
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
      vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
      vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
      vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
    end,
  },
}

-- @variable                       various variable names
-- @variable.builtin               built-in variable names (e.g. this, self)
-- @variable.parameter             parameters of a function
-- @variable.parameter.builtin     special parameters (e.g. _, it)
-- @variable.member                object and struct fields
-- @constant               constant identifiers
-- @constant.builtin       built-in constant values
-- @constant.macro         constants defined by the preprocessor
-- @module                 modules or namespaces
-- @module.builtin         built-in modules or namespaces
-- @label                  GOTO and other labels (e.g. label: in C), including heredoc labels
-- @string                 string literals
-- @string.documentation   string documenting code (e.g. Python docstrings)
-- @string.regexp          regular expressions
-- @string.escape          escape sequences
-- @string.special         other special strings (e.g. dates)
-- @string.special.symbol  symbols or atoms
-- @string.special.path    filenames
-- @string.special.url     URIs (e.g. hyperlinks)
-- @character              character literals
-- @character.special      special characters (e.g. wildcards)
-- @boolean                boolean literals
-- @number                 numeric literals
-- @number.float           floating-point number literals
-- @type                   type or class definitions and annotations
-- @type.builtin           built-in types
-- @type.definition        identifiers in type definitions (e.g. typedef <type> <identifier> in C)
-- @attribute              attribute annotations (e.g. Python decorators, Rust lifetimes)
-- @attribute.builtin      builtin annotations (e.g. @property in Python)
-- @property               the key in key/value pairs
-- @function               function definitions
-- @function.builtin       built-in functions
-- @function.call          function calls
-- @function.macro         preprocessor macros
-- @function.method        method definitions
-- @function.method.call   method calls
-- @constructor            constructor calls and definitions
-- @operator               symbolic operators (e.g. +, *)
-- @keyword                keywords not fitting into specific categories
-- @keyword.coroutine      keywords related to coroutines (e.g. go in Go, async/await in Python)
-- @keyword.function       keywords that define a function (e.g. func in Go, def in Python)
-- @keyword.operator       operators that are English words (e.g. and, or)
-- @keyword.import         keywords for including modules (e.g. import, from in Python)
-- @keyword.type           keywords defining composite types (e.g. struct, enum)
-- @keyword.modifier       keywords defining type modifiers (e.g. const, static, public)
-- @keyword.repeat         keywords related to loops (e.g. for, while)
-- @keyword.return         keywords like return and yield
-- @keyword.debug          keywords related to debugging
-- @keyword.exception      keywords related to exceptions (e.g. throw, catch)
-- @keyword.conditional         keywords related to conditionals (e.g. if, else)
-- @keyword.conditional.ternary ternary operator (e.g. ?, :)
-- @keyword.directive           various preprocessor directives and shebangs
-- @keyword.directive.define    preprocessor definition directives
-- @punctuation.delimiter  delimiters (e.g. ;, ., ,)
-- @punctuation.bracket    brackets (e.g. (), {}, [])
-- @punctuation.special    special symbols (e.g. {} in string interpolation)
-- @comment                line and block comments
-- @comment.documentation  comments documenting code
-- @comment.error          error-type comments (e.g. ERROR, FIXME, DEPRECATED)
-- @comment.warning        warning-type comments (e.g. WARNING, FIX, HACK)
-- @comment.todo           todo-type comments (e.g. TODO, WIP)
-- @comment.note           note-type comments (e.g. NOTE, INFO, XXX)
-- @markup.strong          bold text
-- @markup.italic          italic text
-- @markup.strikethrough   struck-through text
-- @markup.underline       underlined text (only for literal underline markup!)
-- @markup.heading         headings, titles (including markers)
-- @markup.heading.1       top-level heading
-- @markup.heading.2       section heading
-- @markup.heading.3       subsection heading
-- @markup.heading.4       and so on
-- @markup.heading.5       and so forth
-- @markup.heading.6       six levels ought to be enough for anybody
-- @markup.quote           block quotes
-- @markup.math            math environments (e.g. $ ... $ in LaTeX)
-- @markup.link            text references, footnotes, citations, etc.
-- @markup.link.label      link, reference descriptions
-- @markup.link.url        URL-style links
-- @markup.raw             literal or verbatim text (e.g. inline code)
-- @markup.raw.block       literal or verbatim text as a stand-alone block
-- @markup.list            list markers
-- @markup.list.checked    checked todo-style list markers
-- @markup.list.unchecked  unchecked todo-style list markers
-- @diff.plus              added text (for diff files)
-- @diff.minus             deleted text (for diff files)
-- @diff.delta             changed text (for diff files)
-- @tag                    XML-style tag names (e.g. in XML, HTML, etc.)
-- @tag.builtin            XML-style tag names (e.g. HTML5 tags)
-- @tag.attribute          XML-style tag attributes
-- @tag.delimiter          XML-style tag delimiters
