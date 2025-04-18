
-- maparg({name} [, {mode} [, {abbr} [, {dict}]]])                       *maparg()*
-- 		When {dict} is omitted or zero: Return the rhs of mapping
-- 		{name} in mode {mode}.  The returned String has special
-- 		characters translated like in the output of the ":map" command
-- 		listing. When {dict} is TRUE a dictionary is returned, see
-- 		below. To get a list of all mappings see |maplist()|.
--
-- 		When there is no mapping for {name}, an empty String is
-- 		returned if {dict} is FALSE, otherwise returns an empty Dict.
-- 		When the mapping for {name} is empty, then "<Nop>" is
-- 		returned.
--
-- 		The {name} can have special key names, like in the ":map"
-- 		command.
--
-- 		{mode} can be one of these strings:
-- 			"n"	Normal
-- 			"v"	Visual (including Select)
-- 			"o"	Operator-pending
-- 			"i"	Insert
-- 			"c"	Cmd-line
-- 			"s"	Select
-- 			"x"	Visual
-- 			"l"	langmap |language-mapping|
-- 			"t"	Terminal
-- 			""	Normal, Visual and Operator-pending
-- 		When {mode} is omitted, the modes for "" are used.
--
-- 		When {abbr} is there and it is |TRUE| use abbreviations
-- 		instead of mappings.
--
-- 		When {dict} is there and it is |TRUE| return a dictionary
-- 		containing all the information of the mapping with the
-- 		following items:			*mapping-dict*
-- 		  "lhs"	     The {lhs} of the mapping as it would be typed
-- 		  "lhsraw"   The {lhs} of the mapping as raw bytes
-- 		  "lhsrawalt" The {lhs} of the mapping as raw bytes, alternate
-- 			      form, only present when it differs from "lhsraw"
-- 		  "rhs"	     The {rhs} of the mapping as typed.
-- 		  "silent"   1 for a |:map-silent| mapping, else 0.
-- 		  "noremap"  1 if the {rhs} of the mapping is not remappable.
-- 		  "script"   1 if mapping was defined with <script>.
-- 		  "expr"     1 for an expression mapping (|:map-<expr>|).
-- 		  "buffer"   1 for a buffer local mapping (|:map-local|).
-- 		  "mode"     Modes for which the mapping is defined. In
-- 			     addition to the modes mentioned above, these
-- 			     characters will be used:
-- 			     " "     Normal, Visual and Operator-pending
-- 			     "!"     Insert and Commandline mode
-- 				     (|mapmode-ic|)
-- 		  "sid"	     The script local ID, used for <sid> mappings
-- 			     (|<SID>|).  Negative for special contexts.
-- 		  "scriptversion"  The version of the script, always 1.
-- 		  "lnum"     The line number in "sid", zero if unknown.
-- 		  "nowait"   Do not wait for other, longer mappings.
-- 			     (|:map-<nowait>|).
-- 		  "abbr"     True if this is an |abbreviation|.
-- 		  "mode_bits" Nvim's internal binary representation of "mode".
-- 			     |mapset()| ignores this; only "mode" is used.
-- 			     See |maplist()| for usage examples. The values
-- 			     are from src/nvim/state_defs.h and may change in
-- 			     the future.
