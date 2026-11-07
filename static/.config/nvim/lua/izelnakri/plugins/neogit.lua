-- Neogit: magit-style git UI (stage hunks/lines, commit, branch, push, rebase) — the in-editor lazygit.
-- <leader>gg status (or `gg` / `neogit` in a shell), then press `?` for every popup. lazygit-style extras:
-- a diff preview on the right (| style, = hide, + wider, ^d/^u scroll), <cr> expands a file's hunks, e edits,
-- a stages/unstages all, and in `gg` <space> stages/unstages like lazygit. Magit keys: s/u stage/unstage (works on files, hunks or
-- a visual line selection), x discard, c commit, b branch, P push, p pull, f fetch, r rebase, Z stash, l log,
-- d diff (opens diffview), <tab> fold, {/} hunks, <c-r> refresh, q close.
-- Review tools (tuicr/diffview) are in diffview.lua under the same <leader>g prefix.

-- parrots-of-paradise via home-manager's ~/.config/system-colors.json (base16, no '#'). Neogit otherwise derives its
-- colors from highlight groups, and this theme's `String` is yellow, which would make additions yellow.
local function palette()
  local ok, colors = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.expand("~/.config/system-colors.json")), ""))
  end)
  colors = ok and colors or {}
  local function c(name, fallback)
    return "#" .. (colors[name] or fallback)
  end

  return {
    red = c("base08", "EF5D32"),
    orange = c("base09", "EFAA32"),
    yellow = c("base0A", "FFD580"),
    green = c("base0B", "3a9d4b"),
    cyan = c("base0C", "7DAF9C"),
    blue = c("base0D", "85B1DD"),
    purple = c("base0E", "B389D6"),
    -- Same add/delete line tints as the tuicr theme (static/.config/tuicr/themes/parrots-of-paradise.toml):
    line_green = "#14402a",
    line_red = "#46201a",
  }
end

return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- `d` diff popup & side-by-side commit diffs
    "nvim-telescope/telescope.nvim", -- fuzzy branch/commit/file pickers
  },
  init = function()
    -- `neogit` / `gg` in a shell (pkgs/neogit.nix) open nvim straight into the status screen; there `q`
    -- quits nvim like lazygit instead of leaving an empty editor behind. Scheduled so it wins over
    -- neogit's own buffer-local `q`.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NeogitStatus",
      callback = function(event)
        -- lazygit-style diff preview on the right of the status list and lazygit's staging keys
        -- (izelnakri/neogit_preview.lua, izelnakri/neogit_keys.lua).
        require("izelnakri.neogit_preview").attach(event.buf)
        require("izelnakri.neogit_keys").attach(event.buf)
        if vim.g.neogit_standalone ~= 1 then
          return
        end
        vim.schedule(function()
          vim.keymap.set("n", "q", "<cmd>confirm qa<cr>", { buffer = event.buf, desc = "Quit neogit" })
          -- No bufferline row with the empty start buffer, just the git UI. bufferline loads on VeryLazy
          -- and turns the tabline back on, so hide it again after that too.
          vim.o.showtabline = 0
          vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            once = true,
            callback = function()
              vim.schedule(function()
                vim.o.showtabline = 0
              end)
            end,
          })
        end)
      end,
    })
  end,
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neo[g]it status" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "[C]ommit" },
    { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "[B]ranch (checkout/create/...)" },
    { "<leader>gl", "<cmd>Neogit log<cr>", desc = "[L]og" },
    { "<leader>gP", "<cmd>Neogit push<cr>", desc = "[P]ush" },
  },
  opts = {
    kind = "tab", -- full-screen like lazygit; `q` returns to where you were
    graph_style = "unicode",
    process_spinner = true,
    treesitter_diff_highlight = true, -- syntax colors inside inline diffs
    word_diff_highlight = true,
    remember_settings = true, -- popup switches (e.g. --force-with-lease) persist per repo
    fetch_after_checkout = true,
    sort_branches = "-committerdate",
    auto_show_console_on = "error", -- only pop the git console when a command fails
    disable_insert_on_commit = "auto",

    integrations = { telescope = true, diffview = true },
    diff_viewer = "diffview",
    highlight = palette(),
    signs = {
      hunk = { "", "" },
      item = { "▸", "▾" },
      section = { "▸", "▾" },
    },

    status = { recent_commit_count = 20 },
    sections = {
      recent = { folded = false }, -- what the agent just committed, right under the working tree
      stashes = { folded = true },
    },
    commit_editor = {
      kind = "tab",
      show_staged_diff = true,
      staged_diff_split_kind = "vsplit", -- message left, what you're committing right
      spell_check = true,
    },
    commit_view = { kind = "vsplit" },

    mappings = {
      status = {
        -- Peek{Up,Down} (log/refs/stash/reflog views) default to <C-k>/<C-j>, which move between windows
        -- everywhere else (keymaps.lua); keep them for that and peek with Alt instead:
        ["<c-k>"] = false,
        ["<c-j>"] = false,
        ["<m-k>"] = "PeekUp",
        ["<m-j>"] = "PeekDown",
        -- lazygit's `e`; izelnakri/neogit_keys.lua overrides it to edit in a tab that returns here on :q,
        -- and <cr> on a file expands its hunks.
        ["e"] = "GoToFile",
      },
    },
  },
}

-- NOTE: Previous spec, before configuring it:
-- return {
--   "NeogitOrg/neogit",
--   dependencies = {
--     "nvim-lua/plenary.nvim", -- required
--     "sindrets/diffview.nvim", -- optional - Diff integration
--     "nvim-telescope/telescope.nvim", -- optional
--   },
--   config = true,
-- }
