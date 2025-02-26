--- TODO: Read up on ext_messages
--- Read up on :screen and :cmd-line, session(attach)
--- READ ON: vim.ui.attach AND nvim_ui_attach
--- TODO: Query g< window, is it a window(?) -> can I get its buffer, close the window and display it?
--- ": Register saves the last command!
--- READ UP ON uimeths.attach. ext_linegrid, ext_multigrid

--- TODO: Implement buffer history and make stdout always display on the right side window,
--- TODO: Also make it editable with a command(then a keybind) -> This is what I am doing now

vim.api.nvim_create_user_command(
  "RmSwp",
  "!rm /var/tmp/*.swp || rm ~/.local/state/nvim/swap/*.swp",
  { desc = "Remove .swp files" }
)
-- If you did this already, delete the swap file "/home/izelnakri/.local/state/nvim/swap//%home%izelnakri%.config%home-manager%flake.nix.swp"

vim.api.nvim_create_user_command("Name", "!echo % | wl-copy", { desc = "Copy filename to clipboard" })
vim.api.nvim_create_user_command("Buffer", "%y+", { desc = "Copy buffer contents to clipboard" })
vim.api.nvim_create_user_command(
  "Colors",
  "vnew | :put=execute(':hi') | set buflisted! | set filetype=vim",
  { desc = "Show highlight groups" }
)
-- NOTE: maybe Set 'cmdheight' to 2 or higher.
vim.api.nvim_create_user_command("Msgs", function(param)
  local messages = vim.split(vim.fn.execute("messages", "silent"), "\n")

  vim.cmd("vnew messages") -- NOTE: check if there is right buffer or create one
  vim.bo.filetype = "messages"
  -- NOTE: Complete this

  vim.api.nvim_buf_set_lines(
    vim.api.nvim_get_current_buf(),
    0,
    -1,
    false,
    messages
    -- { filetype = "messages" } -- NOTE: is this legit?
  )

  -- TODO: send the cursor to very end
end, { desc = "Show last stdout return on the right side" })
vim.api.nvim_create_user_command("Msg", function(param)
  vim.api.nvim_feedkeys("g<", "n", false)
end, { desc = "Show last stdout return on the right side" })

vim.cmd([[
function! Redir(cmd, rng, start, end)
	for win in range(1, winnr('$'))
		if getwinvar(win, 'scratch')
			execute win . 'windo close'
		endif
	endfor
	if a:cmd =~ '^!'
		let cmd = a:cmd =~' %'
			\ ? matchstr(substitute(a:cmd, ' %', ' ' . shellescape(escape(expand('%:p'), '\')), ''), '^!\zs.*')
			\ : matchstr(a:cmd, '^!\zs.*')
		if a:rng == 0 let output = systemlist(cmd)
		else
			let joined_lines = join(getline(a:start, a:end), '\n') let cleaned_lines = substitute(shellescape(joined_lines), "'\\\\''", "\\\\'", 'g')
			let output = systemlist(cmd . " <<< $" . cleaned_lines)
		endif
	else
		redir => output
		execute a:cmd
		redir END
		let output = split(output, "\n")
	endif
	vnew
	let w:scratch = 1
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
	call setline(1, output)
endfunction

" This command definition includes -bar, so that it is possible to "chain" Vim commands.
" Side effect: double quotes can't be used in external commands
command! -nargs=1 -complete=command -bar -range Redir silent call Redir(<q-args>, <range>, <line1>, <line2>)

" This command definition doesn't include -bar, so that it is possible to use double quotes in external commands.
" Side effect: Vim commands can't be "chained".
command! -nargs=1 -complete=command -range Redir silent call Redir(<q-args>, <range>, <line1>, <line2>)
]])

-- TODO: Redir doesnt work for lua expression execution that return the stdout, fix that one as well
