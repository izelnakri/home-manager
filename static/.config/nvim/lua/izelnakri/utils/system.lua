-- NOTE: check nio.process and plenary.job
System = {}

return System

-- uv.exepath()                                                      *uv.exepath()*
--                 Returns: `string` or `fail`
-- uv.cwd()                                                              *uv.cwd()*
--                 Returns: `string` or `fail`
-- uv.chdir({cwd})                                                     *uv.chdir()*
--                 Sets the current working directory with the string `cwd`. Returns: `0` or `fail`

-- environ()                                                            *environ()*
-- 		Return all of environment variables as dictionary. You can
-- 		check if an environment variable exists like this: >vim
-- 			echo has_key(environ(), 'HOME')
-- <		Note that the variable name may be CamelCase; to ignore case
-- 		use this: >vim
-- 			echo index(keys(environ()), 'HOME', 0, 1) != -1

-- executable({expr})                                                *executable()*
-- 		This function checks if an executable with the name {expr}
-- 		exists.  {expr} must be the name of the program without any
-- 		arguments. executable() uses the value of $PATH and/or the normal
-- 		searchpath for programs.		*PATHEXT*
-- 		On MS-Windows the ".exe", ".bat", etc. can optionally be
-- 		included.  Then the extensions in $PATHEXT are tried.  Thus if
-- 		"foo.exe" does not exist, "foo.exe.bat" can be found.  If
-- 		$PATHEXT is not set then ".exe;.com;.bat;.cmd" is used.  A dot
-- 		by itself can be used in $PATHEXT to try using the name
-- 		without an extension.  When 'shell' looks like a Unix shell,
-- 		then the name is also tried without adding an extension.
-- 		On MS-Windows it only checks if the file exists and is not a
-- 		directory, not if it's really executable.
-- 		On Windows an executable in the same directory as Vim is
-- 		always found (it is added to $PATH at |startup|).
-- 		The result is a Number:
-- 			1	exists
-- 			0	does not exist
-- 		|exepath()| can be used to get the full path of an executable.
--
-- execute({command} [, {silent}])                                      *execute()*
-- 		Execute {command} and capture its output.
-- 		If {command} is a |String|, returns {command} output.
-- 		If {command} is a |List|, returns concatenated outputs.
-- 		Line continuations in {command} are not recognized.
-- 		Examples: >vim
-- 			echo execute('echon "foo"')
-- <			foo >vim
-- 			echo execute(['echon "foo"', 'echon "bar"'])
-- <			foobar
--
-- 		The optional {silent} argument can have these values:
-- 			""		no `:silent` used
-- 			"silent"	`:silent` used
-- 			"silent!"	`:silent!` used
-- 		The default is "silent".  Note that with "silent!", unlike
-- 		`:redir`, error messages are dropped.
--
-- 		To get a list of lines use `split()` on the result: >vim
-- 			execute('args')->split("\n")
--
-- <		This function is not available in the |sandbox|.
-- 		Note: If nested, an outer execute() will not observe output of
-- 		the inner calls.
-- 		Note: Text attributes (highlights) are not captured.
-- 		To execute a command in another window than the current one
-- 		use `win_execute()`.

-- exepath({expr})                                                      *exepath()*
-- 		Returns the full path of {expr} if it is an executable and
-- 		given as a (partial or full) path or is found in $PATH.
-- 		Returns empty string otherwise.
-- 		If {expr} starts with "./" the |current-directory| is used.

-- getenv({name})                                                        *getenv()*
-- 		Return the value of environment variable {name}.  The {name}
-- 		argument is a string, without a leading '$'.  Example: >vim
-- 			myHome = getenv('HOME')
--
-- <		When the variable does not exist |v:null| is returned.  That
-- 		is different from a variable set to an empty string.
-- 		See also |expr-env|.

-- setenv({name}, {val})                                                 *setenv()*
-- 		Set environment variable {name} to {val}.  Example: >vim
-- 			call setenv('HOME', '/home/myhome')
--
-- <		When {val} is |v:null| the environment variable is deleted.
-- 		See also |expr-env|.
