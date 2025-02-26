--- @class TagStack
--- @field curidx number Current item index
--- @field items Tag[] NOTE: Is it correct?!

--- @class Tag
--- @field bufnr number Buffer number
--- @field from number[] Cursor position before tag jump { lnum, col }
--- @field matchnr number Tag id, used when multiple same names exist
--- @field tagname string Name of the tag

-- NOTE: is it a modified version of the tagstack?

TagStack = {}

function TagStack.peek(winnr)
  return vim.api.gettagstack(winnr)
end

-- NOTE: is the difference between settagstack action: 'r' and 't' is the modification of the curidx? - Check this
function TagStack.replace(winnr, tags) end

function TagStack.append(winnr, tags) end

return TagStack

-- settagstack({nr}, {dict} [, {action}])                           *settagstack()*
-- 		Modify the tag stack of the window {nr} using {dict}.
-- 		{nr} can be the window number or the |window-ID|.
--
-- 		For a list of supported items in {dict}, refer to
-- 		|gettagstack()|. "curidx" takes effect before changing the tag
-- 		stack.
-- 							*E962*
-- 		How the tag stack is modified depends on the {action}
-- 		argument:
-- 		- If {action} is not present or is set to 'r', then the tag
-- 		  stack is replaced.
-- 		- If {action} is set to 'a', then new entries from {dict} are
-- 		  pushed (added) onto the tag stack.
-- 		- If {action} is set to 't', then all the entries from the
-- 		  current entry in the tag stack or "curidx" in {dict} are
-- 		  removed and then new entries are pushed to the stack.
--
-- 		The current index is set to one after the length of the tag
-- 		stack after the modification.
--
-- 		Returns zero for success, -1 for failure.
--
-- 		Examples (for more examples see |tagstack-examples|):
-- 		    Empty the tag stack of window 3: >vim
-- 			call settagstack(3, {'items' : []})
--
-- <		    Save and restore the tag stack: >vim
-- 			let stack = gettagstack(1003)
-- 			" do something else
-- 			call settagstack(1003, stack)
-- 			unlet stack
