-- A stateless module inspired by JavaScript's standard array library

List = {}

---Returns the last element of the table
---@param list table: Target table
---@return any: Last element of the table
function List.last(list)
  return list[#list]
end

---Concatenates two or more lists.
---@param list table: The first list
---@param ... table: Additional lists to concatenate
---@return table: The concatenated list
function List.concat(list, ...)
  local result = vim.deepcopy(list)
  for _, copied_list in pairs({ ... }) do
    for _, value in pairs(copied_list) do
      table.insert(result, value)
    end
  end
  return result
end

---Deletes a specific item from a list, once from left
---@param list table: The first list
---@param item any
---@return table: The concatenated list
function List.delete(list, item)
  local position = List.index_of(list, item)

  if position then
    table.remove(list, position)
  end

  return list
end

List.is_list = vim.isarray

---Finds the first index of the given value in the list.
---@param list table: The list to search
---@param value any: The value to find
---@return number?: The index of the value, or nil if not found
function List.index_of(list, value)
  for index, list_value in pairs(list) do
    if list_value == value then
      return index
    end
  end
end

---Returns an iterator for the key-value pairs in the list.
---@param list table: The list to get entries from
---@return Iter: An iterator for key-value pairs
function List.entries(list)
  return vim.iter(pairs(list))
end

---Checks if all elements in the list satisfy the predicate.
---@param list table: The list to check
---@param predicate function: A function that takes an element and returns a boolean
---@return boolean: True if all elements satisfy the predicate, false otherwise
function List.every(list, predicate)
  return vim.iter(list):all(predicate)
end

List.all = List.every

---Fills elements of the list with a static value from start to end.
---@param list table: The list to fill
---@param value any: The value to fill the list with
---@param start number: The start index (inclusive)
---@param finish number: The end index (inclusive)
---@return table: The modified list
function List.fill(list, value, start, finish)
  local len = #list
  for index = start or 1, finish or len do
    list[index] = value
  end
  return list
end

---Filters elements of the list based on a predicate function.
---@param list table: The list to filter
---@param predicate function: A function that takes an element and returns a boolean
---@return table: A new list containing only the elements that satisfy the predicate
function List.filter(list, predicate)
  return vim.iter(list):filter(predicate):totable()
end

---Finds the first element that satisfies the predicate.
---@param list table: The list to search
---@param predicate function: A function that takes an element and returns a boolean
---@return any: The first element that satisfies the predicate, or nil if none found
function List.find(list, predicate)
  return vim.iter(list):find(predicate)
end

---Finds the index of the first element that satisfies the predicate.
---@param list table: The list to search
---@param predicate function: A function that takes an element and returns a boolean
---@return number?: The index of the first element that satisfies the predicate, or nil if none found
function List.find_index(list, predicate)
  for index, value in pairs(list) do
    if predicate(value) then
      return index
    end
  end
end

---Finds the last element that satisfies the predicate.
---@param list table: The list to search
---@param predicate function: A function that takes an element and returns a boolean
---@return any: The last element that satisfies the predicate, or nil if none found
function List.find_last(list, predicate)
  for index = #list, 1, -1 do
    if predicate(list[index]) then
      return list[index]
    end
  end
end

---Finds the index of the last element that satisfies the predicate.
---@param list table: The list to search
---@param predicate function: A function that takes an element and returns a boolean
---@return number?: The index of the last element that satisfies the predicate, or nil if none found
function List.find_last_index(list, predicate)
  for index = #list, 1, -1 do
    if predicate(list[index]) then
      return index
    end
  end
end

local function flatten(list, result)
  for _, value in pairs(list) do
    if type(value) == "table" then
      flatten(value, result)
    else
      table.insert(result, value)
    end
  end

  return result
end

---Flattens a nested list.
---@param list table: The list to flatten
---@return table: A new flattened list
function List.flatten(list)
  return flatten(list, {})
end

List.flat = List.flatten

---Executes a provided function once for each list element.
---@param list table: The list to iterate
---@param callback function: A function that takes an element and its index
---@return table: The provided list, unchanged.
function List.each(list, callback)
  for index, value in pairs(list) do
    callback(value, index)
  end

  return list
end

---Determines whether the list includes a certain element.
---@param list table: The list to check
---@param value any: The value to search for
---@return boolean: True if the value is found, false otherwise
function List.includes(list, value)
  return vim.iter(list):any(function(list_value)
    return list_value == value
  end)
end

---Joins all elements of the list into a string.
---@param list table: The list to join
---@param separator string: The separator to use between elements (default is ",")
---@return string: A string with all list elements joined by the separator
function List.join(list, separator)
  return table.concat(list, separator or ",")
end

---Returns an iterator for the keys in the list.
---@param list table: The list to get keys from
---@return Iter: An iterator for the keys
function List.keys(list)
  return vim.iter(pairs(list)):map(function(index)
    return index
  end)
end

---Returns the last index of the specified value in the list.
---@param list table: The list to search
---@param value any: The value to search for
---@return number?: The last index of the value, or nil if not found
function List.last_index_of(list, value)
  for index = #list, 1, -1 do
    if list[index] == value then
      return index
    end
  end
end

---Maps elements of the list using a transformation function.
---@param list table: The list to map
---@param transform function: A function that takes an element and returns a new element
---@return table: A new list containing the transformed elements
function List.map(list, transform)
  return vim.iter(list):map(transform):totable()
end

---Adds one or more elements to the end of the list and return the list
---@param list table: The list to modify
---@param ... any: The elements to add
---@return table: The new list with the added value
function List.add(list, ...)
  for _, value in pairs({ ... }) do
    table.insert(list, value)
  end

  return list
end

---Adds one or more elements to the end of the list and return the length
---@param list table: The list to modify
---@param ... any: The elements to add
---@return number: The new length of the list
function List.push(list, ...)
  for _, value in pairs({ ... }) do
    table.insert(list, value)
  end

  return #list
end

---Removes the last element from the list and returns it.
---@param list table: The list to modify
---@return any: The removed element
function List.pop(list)
  return table.remove(list)
end

---Reduces the list to a single value using a reducer function.
---@param list table: The list to reduce
---@param reducer function: A function that takes an accumulator and a list element and returns a new accumulator
---@param initial any: The initial value of the accumulator
---@return any: The final value of the accumulator after processing all list elements
function List.reduce(list, reducer, initial)
  local result = initial

  for index, value in pairs(list) do
    result = reducer(result, value, index)
  end

  return result
end

List.fold = List.reduce

---Reduces the list to a single value using a reducer function, processing from right to left.
---@param list table: The list to reduce
---@param reducer function: A function that takes an accumulator and a list element and returns a new accumulator
---@param initial? any: The initial value of the accumulator
---@return any: The final value of the accumulator after processing all list elements
function List.reduce_right(list, reducer, initial)
  local accumulator = initial

  for index = #list, 1, -1 do
    accumulator = reducer(accumulator, list[index], index)
  end

  return accumulator
end

---Reverses the list in place.
---@param list table: The list to reverse
---@return table: The reversed list
function List.reverse(list)
  local len = #list
  for index = 1, math.floor(len / 2) do
    list[index], list[len - index + 1] = list[len - index + 1], list[index]
  end
  return list
end

---Removes the first element from the list and returns it.
---@param list table: The list to modify
---@return any: The removed element
function List.shift(list)
  return table.remove(list, 1)
end

---Returns a shallow copy of a portion of the list into a new list.
---@param list table: The list to slice
---@param start number: The start index (inclusive, default is 1)
---@param finish? number: The end index (inclusive, default is length of the list)
---@return table: A new list containing the sliced elements
function List.slice(list, start, finish)
  local result = {}

  for index = start or 1, finish or #list do
    table.insert(result, list[index])
  end

  return result
end

---Takes an amount of elements from the beginning or the end of the list.
---@param list table: The list to slice
---@param amount number: Amount of elements to take, sign determines whether from the beginning or end
---@return table: A new list containing taken elements
function List.take(list, amount)
  if amount > 0 then
    return List.slice(list, 1, amount)
  else
    return List.slice(list, #list, #list - amount)
  end
end

---Checks if at least one element in the list satisfies the predicate.
---@param list table: The list to check
---@param predicate function: A function that takes an element and returns a boolean
---@return boolean: True if at least one element satisfies the predicate, false otherwise
function List.some(list, predicate)
  return vim.iter(list):any(predicate)
end

List.any = List.some

---Removes the first occurrence of an item from the list
---@param list table: The list to remove items from
---@param item any: The element to remove
---@param times? number: Amount of times to remove the item from a list. It is 1 by default.
---@return table: The list with the removed item
function List.remove(list, item, times)
  times = times or 1
  local count = 0
  local i = 1

  while i <= #list and count < times do
    if list[i] == item then
      table.remove(list, i) -- Remove the item at index i
      count = count + 1
    else
      i = i + 1 -- Move to the next element only if no removal happened
    end
  end

  return list
end

---Sorts the list in place.
---@param list table: The list to sort
---@param comparator function: (optional) A function that defines the sort order. Defaults to ascending order.
---@return table: The sorted list
function List.sort(list, comparator)
  table.sort(list, comparator)
  return list
end

---Adds one or more elements to the beginning of the list, mutates the list
---@param list table: The list to modify
---@param ... any: The elements to add
---@return number: The new length of the list
function List.unshift(list, ...)
  local args = { ... }
  for index = #args, 1, -1 do
    table.insert(list, 1, args[index])
  end
  return #list
end

---Returns an iterator for the values in the list.
---@param list table: The list to get values from
---@return Iter: An iterator for the values
function List.values(list)
  return vim.iter(list)
end

---Returns a new array with a modified element at the specified index.
---@param list table: The original list
---@param index number: The index of the element to modify
---@param value any: The new value to set at the specified index
---@return table: A new list with the modified element
function List.with(list, index, value)
  local new_list = vim.deepcopy(list)
  new_list[index] = value
  return new_list
end

return List
