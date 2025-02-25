-- A stateless module inspired by JavaScript's String standard library

String = {}

---Returns the character at the specified index.
---@param str string: The string to index.
---@param index number: The index of the character. Supports negative indices.
---@return string: The character at the specified index.
function String.at(str, index)
  local len = #str
  if index < 0 then
    index = len + index + 1
  end
  if index < 1 or index > len then
    return ""
  end
  return str:sub(index, index)
end

---Returns the UTF-8 code number of the character at the specified index.
---@param str string: The string to index.
---@param index number: The index of the character. Supports negative indices.
---@return number?: The UTF-8 code of the character at the specified index, nil if its empty string
function String.char_code_at(str, index)
  local char = String.at(str, index)
  if char == "" then
    return nil
  end
  return string.byte(char)
end

---Concatenates multiple strings.
---@param ... string: Strings to concatenate.
---@return string: The concatenated string.
function String.concat(...)
  return table.concat({ ... })
end

String.ends_with = vim.endswith

---Checks if the string includes the specified substring.
---@param str string: The string to check.
---@param substr string: The substring to check for.
---@return boolean: True if the string includes the substring, false otherwise.
function String.includes(str, substr)
  return str:find(substr, 1, true) ~= nil
end

---Returns the index of the first occurrence of the specified substring.
---@param str string: The string to search.
---@param substr string: The substring to search for.
---@return number?: The index of the first occurrence of the substring, or nil if not found.
function String.index_of(str, substr)
  local index = str:find(substr, 1, true)
  return index and index or nil
end

---Returns the index of the last occurrence of the specified substring.
---@param str string: The string to search.
---@param substr string: The substring to search for.
---@return number?: The index of the last occurrence of the substring, or nil if not found.
function String.last_index_of(str, substr)
  local index, last_index = 1, nil
  while true do
    index = str:find(substr, index, true)
    if not index then
      break
    end
    last_index = index
    index = index + 1
  end
  return last_index
end

---Matches the string against a pattern.
---@param str string: The string to match.
---@param pattern string: The pattern to match.
---@return table: The first match
function String.match(str, pattern)
  return { str:match(pattern) }
end

---Matches the string against a pattern and returns an iterator.
---@param str string: The string to match.
---@param pattern string: The pattern to match.
---@return Iter: An iterator over the matches.
function String.match_all(str, pattern)
  local function iterator(s, pattern)
    return function(_, last_index)
      return (str:find(pattern, last_index + 1))
    end, nil, 0
  end
  return vim.iter(iterator(str, pattern))
end

---Pads the string at the end with the specified padding.
---@param str string: The string to pad.
---@param length number: The length of the result string.
---@param pad string: The padding string.
---@return string: The padded string.
function String.pad_end(str, length, pad)
  pad = pad or " "
  while #str < length do
    str = str .. pad
  end
  return str
end

---Pads the string at the start with the specified padding.
---@param str string: The string to pad.
---@param length number: The length of the result string.
---@param pad string: The padding string.
---@return string: The padded string.
function String.pad_start(str, length, pad)
  pad = pad or " "
  while #str < length do
    str = pad .. str
  end
  return str
end

---Repeats the string the specified number of times.
---@param str string: The string to repeat.
---@param count number: The number of times to repeat the string.
---@return string: The repeated string.
function String.rep(str, count)
  return str:rep(count)
end

String.reverse = string.reverse

---Replaces the first occurrence of a pattern with a replacement.
---@param str string: The string to modify.
---@param pattern string: The pattern to replace.
---@param replacement string: The replacement string.
---@param plain_text? boolean: Whether to escape the pattern for lua special characters
---@return string, integer: The modified string.
function String.replace(str, pattern, replacement, plain_text)
  if plain_text then
    local escaped_pattern = string.gsub(pattern, "([^%w])", "%%%1")

    return str:gsub(escaped_pattern, replacement, 1)
  end

  -- check pattern to see if it needs escaping for special characters:
  return str:gsub(pattern, replacement, 1)
end

---Replaces all occurrences of a pattern with a replacement.
---@param str string: The string to modify.
---@param pattern string: The pattern to replace.
---@param replacement string: The replacement string.
---@param plain_text? boolean: Whether to escape the pattern for lua special characters
---@return string, integer: The modified string, number of changed occurences
function String.replace_all(str, pattern, replacement, plain_text)
  if plain_text then
    local escaped_pattern = string.gsub(pattern, "([^%w])", "%%%1")

    return str:gsub(escaped_pattern, replacement)
  end

  return str:gsub(pattern, replacement)
end

String.search = string.find

---Extracts a section of the string and returns it as a new string. Adjusted lua string:sub for more JS-like handling
---@param str string: The string to slice.
---@param start? number: The start index.
---@param finish? number: The end index (optional).
---@return string: The sliced string.
function String.slice(str, start_index, end_index)
  local len = #str

  -- Handle default values
  start_index = start_index or 1
  end_index = end_index or (len + 1) -- NOTE: Is this correct assumption(?)

  -- Handle negative indices
  if start_index < 0 then
    start_index = len + start_index + 1
  end
  if end_index < 0 then
    end_index = len + end_index + 1
  end

  -- Clamp indices to the bounds of the string
  if start_index < 1 then
    start_index = 1
  end
  if end_index > len + 1 then
    end_index = len + 1
  end

  if start_index >= end_index then
    return ""
  end

  return str:sub(start_index, end_index - 1)
end

String.split = vim.split

String.starts_with = vim.startswith

String.substring = string.sub

String.to_lower_case = string.lower

String.to_upper_case = string.upper

String.trim = vim.trim

---Trims whitespace from the start of the string.
---@param str string: The string to trim.
---@return string: The trimmed string.
function String.trim_start(str)
  return str:match("^%s*(.-)$")
end

---Trims whitespace from the end of the string.
---@param str string: The string to trim.
---@return string: The trimmed string.
function String.trim_end(str)
  return str:match("^(.-)%s*$")
end

---Returns the length of the string.
---@param str string: The string to measure.
---@return number: The length of the string.
function String.length(str)
  return #str
end

return String
