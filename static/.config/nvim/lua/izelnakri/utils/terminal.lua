-- NOTE: check nio.process and plenary.job

Terminal = {}

my_iter = vim.iter({ 1, 2 })

--- @class TerminalTask
--- @field cmd string[] Command name and args
--- @field cwd string Current working directory
--- @field env table Current ENV of the task
--- @field stdout table Current stdout of the task
--- @field stderr table Current stderr of the task
--- @field pid integer Pid of the task
--- @field channel_id integer Channel id of the task(is this needed(?), allows sending stdin async
--- @field shell string Target shell
--- @field exit_code? integer Exit code of the process
--- @field duration integer Duration of the process on exit in ms
--- NOTE: maybe also add :wait(integer|nil), :get_duration(), :kill(signal: ineger|string), :write(), :is_closing())
--- TODO: How to associate this to the existing buffer?

--- @class TerminalOpts
--- @field cwd string Current directory (Defaults to project CWD)
--- @field env table Target ENV (Defaults to current ENV)
--- @field shell string Target shell (Defaults to $SHELL)
--- @field timeout integer Time to live, kill the process if it doesnt finish by this time
--- @field detach boolean Detaches the process

--- @param cmd string | string[] Command and args to run as a job
--- @param opts TerminalOpts Configuration options
--- @return TerminalTask Async job that can be awaited, includes the state of the process
function Terminal.open(cmd, opts)
  opts = opts or {}
  normalized_cmd = (type(cmd) == "string" and String.split(cmd, " ")) or cmd

  local terminal = vim.system(normalized_cmd, {}, function(a, b, c)
    vim.notify("on_exit:")
  end)

  return terminal

  -- NOTE: Find a way to embed it in the current_buffer
  -- TODO: TJ uses jobstart and nvim_buf_set_lines()
  -- NOTE: only issue is to send to the stdin of the jobstart everytime I type, delete etc(?)
  -- jobstart -> stdin and stderr to the new buffer(nvim_open_term)
  -- Gets a nvim_open_term() on_input -> nvim_chan_send
end

vim.api.nvim_create_user_command("OldIzel", function()
  -- NOTE: The public exposed data should be on exit(stdout_buffer & stderr_buffer, exit_code, duration), also exposes the channel
  full_stdout, full_stderr = nil, nil
  stdout, stderr = {}, {}
  channel_id = vim.fn.termopen("node ~/Github/qunitx/lo.js", {
    on_stdout = function(channel_id, stdout_buffer, c, d)
      vim.notify("stdout:")
      table.insert(stdout, stdout_buffer) -- 85, data?
    end,
    on_stderr = function(channel_id, stderr_buffer, d)
      vim.notify("stderr:")
      table.insert(stderr, stderr_buffer)
    end,
    pty = false,
    -- Also try buffered stuff
    -- TODO: do the
    -- on_stderr = function()
    on_exit = function(a, b, last_event)
      vim.notify("on_exit:")
      full_stdout = List.join(List.flat(stdout), "\n")
      full_stderr = List.join(List.flat(stderr), "\n")
      -- stdout = stdout_buffer[#stdout_buffer - 1]
      -- stderr = stderr_buffer[#stderr_buffer - 1]
    end,
  })
  Utils.notify("channel-id is:")
  Utils.notify(channel_id)

  -- vim.api.nvim_chan_send(result, "izel is king")

  -- local result = vim.api.nvim_exec2("terminal uname -a", { output = true })
end, { desc = "Open terminal" }) -- NOTE: there is a complete callback

return Terminal

-- TODO: This could buffer stderr, try this! But this is for one-shot command? How to display/stream it in buffer?
---@param cmd string[]
---@param opts? {cwd:string, env:table}
-- function M.exec(cmd, opts)
--   opts = opts or {}
--   ---@type string[]
--   local lines
--   local job = vim.fn.jobstart(cmd, {
--     cwd = opts.cwd,
--     pty = false,
--     env = opts.env,
--     stdout_buffered = true,
--     on_stdout = function(_, _lines)
--       lines = _lines
--     end,
--   })
--   vim.fn.jobwait({ job })
--   return lines
-- end

-- :term very_long_taking_command

-- nvim_list_uis()                                              *nvim_list_uis()*
--     Gets a list of dictionaries representing attached UIs.
--
--     Return: ~
--         Array of UI dictionaries, each with these keys:
--         • "height" Requested height of the UI
--         • "width" Requested width of the UI
--         • "rgb" true if the UI uses RGB colors (false implies |cterm-colors|)
--         • "ext_..." Requested UI extensions, see |ui-option|
--         • "chan" |channel-id| of remote UI

-- nvim_open_term({buffer}, {opts})                            *nvim_open_term()*
--     Open a terminal instance in a buffer
--
--     By default (and currently the only option) the terminal will not be
--     connected to an external process. Instead, input send on the channel will
--     be echoed directly by the terminal. This is useful to display ANSI
--     terminal sequences returned as part of a rpc message, or similar.
--
--     Note: to directly initiate the terminal using the right size, display the
--     buffer in a configured window before calling this. For instance, for a
--     floating display, first create an empty buffer using |nvim_create_buf()|,
--     then display it using |nvim_open_win()|, and then call this function. Then
--     |nvim_chan_send()| can be called immediately to process sequences in a
--     virtual terminal having the intended size.
--
--     Attributes: ~
--         not allowed when |textlock| is active
--
--     Parameters: ~
--       • {buffer}  the buffer to use (expected to be empty)
--       • {opts}    Optional parameters.
--                   • on_input: Lua callback for input sent, i e keypresses in
--                     terminal mode. Note: keypresses are sent raw as they would
--                     be to the pty master end. For instance, a carriage return
--                     is sent as a "\r", not as a "\n". |textlock| applies. It
--                     is possible to call |nvim_chan_send()| directly in the
--                     callback however. `["input", term, bufnr, data]`
--                   • force_crlf: (boolean, default true) Convert "\n" to
--                     "\r\n".
--
--     Return: ~
--         Channel id, or 0 on error

-- jobresize({job}, {width}, {height})                                *jobresize()*
-- 		Resize the pseudo terminal window of |job-id| {job} to {width}
-- 		columns and {height} rows.
-- 		Fails if the job was not started with `"pty":v:true`.

-- jobstart({cmd} [, {opts}])                                          *jobstart()*
-- 		Note: Prefer |vim.system()| in Lua (unless using the `pty` option).
-- 		pty = psuedo terminal -> Maybe check!

-- jobwait({jobs} [, {timeout}])                                        *jobwait()*
-- 		Waits for jobs and their |on_exit| handlers to complete.
--
-- 		{jobs} is a List of |job-id|s to wait for.
-- 		{timeout} is the maximum waiting time in milliseconds. If
-- 		omitted or -1, wait forever.
--
-- 		Timeout of 0 can be used to check the status of a job: >vim
-- 			let running = jobwait([{job-id}], 0)[0] == -1
-- <
-- 		During jobwait() callbacks for jobs not in the {jobs} list may
-- 		be invoked. The screen will not redraw unless |:redraw| is
-- 		invoked by a callback.
--
-- 		Returns a list of len({jobs}) integers, where each integer is
-- 		the status of the corresponding job:
-- 			Exit-code, if the job exited
-- 			-1 if the timeout was exceeded
-- 			-2 if the job was interrupted (by |CTRL-C|)
-- 			-3 if the job-id is invalid

-- termopen({cmd} [, {opts}])                                          *termopen()*
-- 		Spawns {cmd} in a new pseudo-terminal session connected
-- 		to the current (unmodified) buffer. Parameters and behavior
-- 		are the same as |jobstart()| except "pty", "width", "height",
-- 		and "TERM" are ignored: "height" and "width" are taken from
-- 		the current window. Note that termopen() implies a "pty" arg
-- 		to jobstart(), and thus has the implications documented at
-- 		|jobstart()|.
--
-- 		Returns the same values as jobstart().
--
-- 		Terminal environment is initialized as in |jobstart-env|,
-- 		except $TERM is set to "xterm-256color". Full behavior is
-- 		described in |terminal|.

-- nvim_ui_term_event({event}, {value})                    *nvim_ui_term_event()*
--     Tells Nvim when a terminal event has occurred
--
--     The following terminal events are supported:
--     • "termresponse": The terminal sent an OSC or DCS response sequence to
--       Nvim. The payload is the received response. Sets |v:termresponse| and
--       fires |TermResponse|.
--
--     Attributes: ~
--         |RPC| only
--
--     Parameters: ~
--       • {event}  Event name
--       • {value}  Event payload

-- let child = Command::new("/bin/cat")
--         .stdin(Stdio::piped())
--         .stdout(Stdio::piped())
-- TODO: READ: /home/izelnakri/Github/neotest/lua/neotest/lib/ui/init.lua
