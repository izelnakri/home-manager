-- A stateless module inspired by JavaScript's Object standard library

Object = {}

---Returns a new object with extended attributes
---@param object table: The object to get source the new object from
---@param object_two table: The object to extend the target object for
---@return table; New object with final key, value pairs
function Object.assign(object, object_two, ...)
  return vim.tbl_deep_extend("force", object, object_two, ...)
end

Object.extend = Object.assign

function Object.is_object(value)
  return (type(value) == "table" or type(getmetatable(value)) == "table") and (not vim.isarray(value))
end

Object.is_empty = vim.tbl_isempty

---Returns an list of key-value pairs for the given object.
---@param object table: The object to get entries from
---@return Iter: An iterator of { key, value } pairs
function Object.entries(object)
  return vim.iter(object) -- NOTE: This is correct
end

---Converts a list of key-value pairs into an object.
---@param entries table: List of { key, value } pairs, can't be an Iter
---@return table: The resulting object
function Object.from_entries(entries)
  local object = {}
  for _, pair in ipairs(entries) do
    object[pair[1]] = pair[2]
  end
  return object
end

---Returns an iterator of all own property names of the given object.
---@param object table: The object to get keys from
---@return Iter: Iterator function
function Object.keys(object)
  return vim.iter(object):map(function(key)
    return key
  end)
end

---Returns an iterator of all own property names sorted of the given object. Its slower than Object.keys()
---@param object table: The object to get sorted keys from
---@return Iter: Iterator function
function Object.sorted_keys(object)
  local result = {}
  for key, _ in pairs(object) do
    table.insert(result, key)
  end

  table.sort(result)

  return vim.iter(result)
end

---@param object table Target object
---@param key string Key reference, supports deep checks
---@return boolean: Whether the key exists or not
function Object.has_key(object, key)
  local keys = vim.split(key, ".", { plain = true })
  local current = object

  for _, k in ipairs(keys) do
    if type(current) ~= "table" then
      return false
    end
    local found = false
    for existing_key in pairs(current) do
      if existing_key == k then
        found = true
        break
      end
    end
    if not found then
      return false
    end
    current = current[k]
  end

  return true
end

---Returns an iterator of all own property values of the given object.
---@param object table: The object to get values from
---@return Iter: Iterator function
function Object.values(object)
  return vim.iter(object):map(function(_, value)
    return value
  end)
end

---Returns the total key count of the object
---@param object table: The object to get values from
---@return number: Total key count of the object
function Object.length(object)
  local count = 0
  for _ in pairs(object) do
    count = count + 1
  end
  return count
end

-- NOTE: There is also vim.tbl_get maybe to use
---Looks up the value on target key_reference or returns nil if there is no value on that key
---@param object table: The object to get the value
---@param key_reference any: Key reference can be any value including strings with "." separator for deep lookup
---@return any?: value when it exists in the object
function Object.get(object, key_reference)
  local keys = vim.split(key_reference, ".", { plain = true })
  local current = object

  for _, k in ipairs(keys) do
    if type(current) ~= "table" then
      return nil
    end
    current = current[k]
  end

  return current
end

---Sets the value on the provided key_reference of an object
---@param object table: The object to set the value
---@param key_reference any: Key reference can be any value including strings with "." separator for deep set
---@param value any: Value to set
---@return table: Return the existing mutated object
function Object.set(object, key_reference, value)
  local keys = vim.split(key_reference, ".", { plain = true })
  local current = object

  for i, k in ipairs(keys) do
    if i == #keys then
      current[k] = value
    else
      if type(current[k]) ~= "table" then
        current[k] = {}
      end
      current = current[k]
    end
  end

  return object
end

---@param object table: The object to insert the key and value pair
---@param key any: Target key
---@param value any: Target value
---@return table: Existing object with the key value pair inserted
function Object.insert(object, key, value)
  object[key] = value

  return object
end

---Removes a key from the object
---@param object table: The object to remove the key from
---@param key_reference any: Key reference can be any value including strings with "." separator for deep removal
---@return table: Return the existing mutated object
function Object.remove(object, key_reference)
  local keys = vim.split(key_reference, ".", { plain = true })
  local current = object

  for i, k in ipairs(keys) do
    if i == #keys then
      current[k] = nil
    else
      if type(current[k]) ~= "table" then
        return object
      end
      current = current[k]
    end
  end

  return object
end

return Object
