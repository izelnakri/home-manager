local M = {}
M.get_current_filetype = function()
  return vim.bo.filetype
end

-- NOTE: maybe a plugin already does this:
function M.keyOf(tbl, value)
  for k, v in pairs(tbl) do
    if v == value then
      return k
    end
  end
  return nil
end

-- NOTE: maybe a plugin already does this:
function M.indexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

return M

-- local function readSnippet(snippetName)
--   local home = vim.fn.expand("$HOME")
--   local filepath = home .. "/.config/nvim/snippets/" .. snippetName
--   local file = io.open(filepath, "r")
--   if file then
--     local content = file:read("*a")
--     file:close()
--     return content
--   else
--     return ""
--   end
-- end
--
-- function M.insertSnippet(snippetName)
--   local content = readSnippet(snippetName)
--   if content ~= "" then
--     vim.fn.append(vim.fn.line("."), content)
--   else
--     print("Snippet not found")
--   end
-- end
--
--

-- type({expr})                                                            *type()*
-- 		The result is a Number representing the type of {expr}.
-- 		Instead of using the number directly, it is better to use the
-- 		v:t_ variable that has the value:
-- 			Number:	    0  |v:t_number|
-- 			String:	    1  |v:t_string|
-- 			Funcref:    2  |v:t_func|
-- 			List:	    3  |v:t_list|
-- 			Dictionary: 4  |v:t_dict|
-- 			Float:	    5  |v:t_float|
-- 			Boolean:    6  |v:t_bool| (|v:false| and |v:true|)
-- 			Null:	    7  (|v:null|)
-- 			Blob:	   10  |v:t_blob|
-- 		For backward compatibility, this method can be used: >vim
-- 			if type(myvar) == type(0) | endif
-- 			if type(myvar) == type("") | endif
-- 			if type(myvar) == type(function("tr")) | endif
-- 			if type(myvar) == type([]) | endif
-- 			if type(myvar) == type({}) | endif
-- 			if type(myvar) == type(0.0) | endif
-- 			if type(myvar) == type(v:true) | endif
-- <		In place of checking for |v:null| type it is better to check
-- 		for |v:null| directly as it is the only value of this type: >vim
-- 			if myvar is v:null | endif
-- <		To check if the v:t_ variables exist use this: >vim
-- 			if exists('v:t_number') | endif
