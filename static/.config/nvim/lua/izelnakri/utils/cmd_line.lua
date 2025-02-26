local echo = function(text)
  vim.api.nvim_echo({ { text } }, true, {})
end

-- vim.cmd("set verbosefile='~/.cache/nvim/messages.log'")
vim.cmd(":let output = ''")

-- NOTE: Move this to utils/cmd_line.lua : CmdLine.lastStdout(), CmdLine.message(), CmdLine.lastLuaREPLMessage()
-- NOTE: There is also CmdwinEnter and CmdwinLeave
-- TODO: Problem is plenary also runs this *at the same time*
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = vim.api.nvim_create_augroup("custom-cmd-enter", {}),
  callback = function()
    vim.cmd(":redir => output")
    -- echo("============START CmdlineEnter============")
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = vim.api.nvim_create_augroup("custom-cmd-leave", {}),
  callback = function()
    vim.schedule(function()
      -- echo("============END CmdlineLeave============")
      vim.cmd(":redir END")
      -- vim.notify(vim.cmd.echo(output))
      vim.g.last_message = vim.g.output
    end)
  end,
})

-- TODO: Use noice.nvim, so map :! to :silent ! NOT needed
vim.api.nvim_create_autocmd("ShellCmdPost", {
  group = vim.api.nvim_create_augroup("custom-shell-post", {}),
  callback = function()
    -- suppress cmd
    -- echo("============END ShellCmdPost============")
    vim.cmd(":redir END")
    -- vim.notify(vim.cmd.echo(output))
    vim.g.last_stdout = vim.g.output

    -- TODO: Make this with
    -- vim.cmd(":vnew stdout | :put=execute('echo last_stdout')")
    -- TODO: Make the stdout selected
  end,
})

CmdLine = {}

return CmdLine

-- setcmdline({str} [, {pos}])                                       *setcmdline()*
-- 		Set the command line to {str} and set the cursor position to
-- 		{pos}.
-- 		If {pos} is omitted, the cursor is positioned after the text.
-- 		Returns 0 when successful, 1 when not editing the command
-- 		line.

-- TODO: There is history toggle than can be achieved with vim.fn
--
--
-- nvim_parse_cmd({str}, {opts})                               *nvim_parse_cmd()*
--     Parse command line.
--
--     Doesn't check the validity of command arguments.
--
--     Attributes: ~
--         |api-fast|
--
--     Parameters: ~
--       • {str}   Command line string to parse. Cannot contain "\n".
--       • {opts}  Optional parameters. Reserved for future use.
--
--     Return: ~
--         Dictionary containing command information, with these keys:
--         • cmd: (string) Command name.
--         • range: (array) (optional) Command range (<line1> <line2>). Omitted
--           if command doesn't accept a range. Otherwise, has no elements if no
--           range was specified, one element if only a single range item was
--           specified, or two elements if both range items were specified.
--         • count: (number) (optional) Command <count>. Omitted if command
--           cannot take a count.
--         • reg: (string) (optional) Command <register>. Omitted if command
--           cannot take a register.
--         • bang: (boolean) Whether command contains a <bang> (!) modifier.
--         • args: (array) Command arguments.
--         • addr: (string) Value of |:command-addr|. Uses short name or "line"
--           for -addr=lines.
--         • nargs: (string) Value of |:command-nargs|.
--         • nextcmd: (string) Next command if there are multiple commands
--           separated by a |:bar|. Empty if there isn't a next command.
--         • magic: (dictionary) Which characters have special meaning in the
--           command arguments.
--           • file: (boolean) The command expands filenames. Which means
--             characters such as "%", "#" and wildcards are expanded.
--           • bar: (boolean) The "|" character is treated as a command separator
--             and the double quote character (") is treated as the start of a
--             comment.
--         • mods: (dictionary) |:command-modifiers|.
--           • filter: (dictionary) |:filter|.
--             • pattern: (string) Filter pattern. Empty string if there is no
--               filter.
--             • force: (boolean) Whether filter is inverted or not.
--           • silent: (boolean) |:silent|.
--           • emsg_silent: (boolean) |:silent!|.
--           • unsilent: (boolean) |:unsilent|.
--           • sandbox: (boolean) |:sandbox|.
--           • noautocmd: (boolean) |:noautocmd|.
--           • browse: (boolean) |:browse|.
--           • confirm: (boolean) |:confirm|.
--           • hide: (boolean) |:hide|.
--           • horizontal: (boolean) |:horizontal|.
--           • keepalt: (boolean) |:keepalt|.
--           • keepjumps: (boolean) |:keepjumps|.
--           • keepmarks: (boolean) |:keepmarks|.
--           • keeppatterns: (boolean) |:keeppatterns|.
--           • lockmarks: (boolean) |:lockmarks|.
--           • noswapfile: (boolean) |:noswapfile|.
--           • tab: (integer) |:tab|. -1 when omitted.
--           • verbose: (integer) |:verbose|. -1 when omitted.
--           • vertical: (boolean) |:vertical|.
--           • split: (string) Split modifier string, is an empty string when
--             there's no split modifier. If there is a split modifier it can be
--             one of:
--             • "aboveleft": |:aboveleft|.
--             • "belowright": |:belowright|.
--             • "topleft": |:topleft|.
--             • "botright": |:botright|.
