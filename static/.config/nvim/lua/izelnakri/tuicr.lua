-- tuicr (GitHub-style review TUI, config: ~/.config/tuicr/config.toml) in a persistent floating terminal.
-- Runs through `cr` (pkgs/cr/cr.sh): `y` ends the review and sends it to the Claude Code pane working on this
-- repo; `:submit` posts it to GitHub as a real PR review; `:q` just closes.
--
-- The float only hides, so going back and forth never loses your place:
--   tuicr `e`      hide the float, open that file at that line here, preview the hunk (stage it: <leader>hs)
--   tuicr <C-g>    hide the float, open neogit (stage lines, commit, push, rebase)
--   <leader>gr     show the review again exactly where you left it (diff re-reads the worktree every second)
-- Keymaps live in plugins/diffview.lua under <leader>g.
local M = {}

--- @type { buf: integer, job: integer?, win: integer?, origin_win: integer?, root: string, args: string[] }?
local review = nil

local function git_root()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
  return vim.v.shell_error == 0 and root or vim.fn.getcwd()
end

local function is_visible()
  return review ~= nil and review.win ~= nil and vim.api.nvim_win_is_valid(review.win)
end

local function show()
  local width = math.floor(vim.o.columns * 0.96)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.92)
  review.origin_win = vim.api.nvim_get_current_win()
  review.win = vim.api.nvim_open_win(review.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = " tuicr  e: edit here · ^g: neogit · y: send to Claude · :submit: GitHub · :q: close ",
    title_pos = "center",
  })
  vim.cmd.startinsert()
end

--- Hide the review (it keeps running) and return to the window it was opened from.
function M.hide()
  if not is_visible() then
    return
  end
  vim.api.nvim_win_hide(review.win)
  review.win = nil
  if review.origin_win and vim.api.nvim_win_is_valid(review.origin_win) then
    vim.api.nvim_set_current_win(review.origin_win)
  end
  vim.cmd.stopinsert()
end

--- Open a review with `cr` args (see `cr --help`), or toggle the one already running.
--- @param args string[]
function M.open(args)
  -- A review whose `cr` already exited (e.g. picker cancelled) only shows its output; start fresh instead.
  if
    review and not (vim.api.nvim_buf_is_valid(review.buf) and review.job and vim.fn.jobwait({ review.job }, 0)[1] == -1)
  then
    M.hide()
    if vim.api.nvim_buf_is_valid(review.buf) then
      vim.api.nvim_buf_delete(review.buf, { force = true })
    end
    review = nil
  end
  if review then
    if is_visible() then
      return M.hide()
    end
    if args and #args > 0 and not vim.deep_equal(args, review.args) then
      vim.notify("Resuming the open review; `:q` it in tuicr to start a different one", vim.log.levels.INFO, {
        title = "tuicr",
      })
    end
    return show()
  end

  review = { buf = vim.api.nvim_create_buf(false, true), root = git_root(), args = args or {} }
  local buf = review.buf
  show()

  review.job = vim.fn.jobstart(vim.list_extend({ "cr" }, vim.deepcopy(review.args)), {
    term = true,
    cwd = review.root,
    on_exit = function(_, code)
      vim.schedule(function()
        -- `cr` reports where the review went (or why not) as its last line:
        local lines = vim.tbl_filter(function(line)
          return line:match("^cr: ")
        end, vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_lines(buf, 0, -1, false) or {})
        if code == 0 then
          M.hide()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
          review = nil
        end
        if lines[#lines] then
          vim.notify(lines[#lines], code == 0 and vim.log.levels.INFO or vim.log.levels.WARN, { title = "tuicr" })
        end
        vim.cmd.checktime() -- Claude/`e` may have changed files under open buffers
      end)
    end,
  })

  -- The global `<esc>` terminal mapping (keymaps.lua) leaves terminal mode; tuicr needs Esc itself
  -- (cancel comment, clear search). <C-\><C-n> still gets back to normal mode.
  vim.keymap.set("t", "<esc>", "<esc>", { buffer = buf, nowait = true })
  vim.keymap.set({ "t", "n" }, "<c-g>", function()
    M.hide()
    vim.cmd("Neogit cwd=" .. vim.fn.fnameescape(review.root))
  end, { buffer = buf, desc = "Hide tuicr, open neogit" })
  vim.keymap.set("n", "q", M.hide, { buffer = buf, desc = "Hide tuicr (<leader>gr brings it back)" })
end

--- Called by tuicr's `e` through pkgs/cr/nvim-shim.sh: show `file` at `line` here, ready to stage.
--- @param file string
--- @param line integer
function M.jump(file, line)
  vim.schedule(function()
    M.hide()
    vim.cmd.edit({ args = { file }, mods = { keepalt = false } })
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd("normal! zz")
    -- gitsigns attaches asynchronously; then show what changed here inline (<leader>hs stages it).
    vim.defer_fn(function()
      pcall(function()
        require("gitsigns").preview_hunk_inline()
      end)
    end, 200)
  end)
end

--- `:submit` only works on a PR. Save & close the open local review, then reopen it as this branch's GitHub
--- PR with its comments copied in (`cr to-pr`), ready for `:submit`.
function M.to_pr()
  local job = review and review.job
  if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
    -- Esc + :w saves a comment still being typed (vim comment box), :w saves the session, :q closes it.
    -- Each goes on its own write: Esc directly followed by ":" reaches tuicr as Alt+: instead.
    -- (`review` is cleared by on_exit while we wait, so only the local `job` is used below.)
    for _, keys in ipairs({ "\27", ":w\r", ":w\r", ":q\r" }) do
      vim.fn.chansend(job, keys)
      vim.wait(150)
    end
    if vim.fn.jobwait({ job }, 5000)[1] == -1 then
      return vim.notify("tuicr didn't close; `:w` and `:q` it, then <leader>gS again", vim.log.levels.WARN, {
        title = "tuicr",
      })
    end
    vim.wait(500, function()
      return review == nil
    end)
  end
  M.open({ "to-pr" })
end

-- Base for branch reviews: origin's default branch (origin/main, origin/master, ...).
function M.default_branch()
  local ref = vim.fn.systemlist({ "git", "-C", git_root(), "rev-parse", "--abbrev-ref", "origin/HEAD" })[1]
  return (vim.v.shell_error == 0 and ref) or "origin/main"
end

-- Pick an open GitHub PR (current branch's PR first) and review it.
function M.pick_pr()
  local root = git_root()
  vim.system(
    { "gh", "pr", "list", "--limit", "50", "--json", "number,title,author,headRefName,isDraft" },
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        return vim.notify(vim.trim(result.stderr or ""), vim.log.levels.ERROR, { title = "gh pr list" })
      end
      local prs = vim.json.decode(result.stdout)
      if #prs == 0 then
        return vim.notify("No open pull requests", vim.log.levels.INFO, { title = "tuicr" })
      end
      local branch = vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })[1]
      table.sort(prs, function(a, b)
        if (a.headRefName == branch) ~= (b.headRefName == branch) then
          return a.headRefName == branch
        end
        return a.number > b.number
      end)
      vim.ui.select(prs, {
        prompt = "Review pull request",
        format_item = function(pr)
          return string.format(
            "#%d %s%s  (@%s, %s)",
            pr.number,
            pr.isDraft and "[draft] " or "",
            pr.title,
            pr.author.login,
            pr.headRefName
          )
        end,
      }, function(pr)
        if pr then
          M.open({ "pr", tostring(pr.number) })
        end
      end)
    end)
  )
end

-- Review the current file's uncommitted changes, starting at the cursor line.
function M.review_file()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return vim.notify("No file in this buffer", vim.log.levels.WARN, { title = "tuicr" })
  end
  local root = git_root()
  local relative = file:sub(1, #root + 1) == root .. "/" and file:sub(#root + 2) or file
  M.open({ "--", "-p", relative, "--line", tostring(vim.fn.line(".")) })
end

return M
