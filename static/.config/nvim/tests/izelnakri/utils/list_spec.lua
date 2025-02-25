local List = require("izelnakri.utils.list")

describe("List module", function()
  local my_list = { 1, 2, 3, 4, 5 }

  it("concat", function()
    local list1 = { 1, 2, 3 }
    local list2 = { 4, 5, 6 }
    local list3 = { 7, 8, 9 }
    local concatenated = List.concat(list1, list2, list3)
    assert.are.same(concatenated, { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
  end)

  it("index_of", function()
    local index = List.index_of(my_list, 3)
    assert.are.equal(index, 3)
    local not_found = List.index_of(my_list, 99)
    assert.are.equal(not_found, nil)
  end)

  it("entries", function()
    local entries = List.entries(my_list)
    local expected = { { 1, 1 }, { 2, 2 }, { 3, 3 }, { 4, 4 }, { 5, 5 } }
    for i, entry in ipairs(entries) do
      assert.are.same(expected[i], entry)
    end
  end)

  it("every", function()
    assert.is_false(List.every(my_list, function(x)
      return x % 2 == 0
    end))
  end)

  it("fill", function()
    local filled_list = List.fill({ 1, 2, 3, 4, 5 }, 0, 2, 4)
    assert.are.same(filled_list, { 1, 0, 0, 0, 5 })
  end)

  it("filter", function()
    local filtered_list = List.filter(my_list, function(x)
      return x > 2
    end)
    assert.are.same(filtered_list, { 3, 4, 5 })
  end)

  it("find", function()
    local found = List.find(my_list, function(x)
      return x > 3
    end)
    assert.are.equal(found, 4)
  end)

  it("find_index", function()
    local found_index = List.find_index(my_list, function(x)
      return x > 2
    end)
    assert.are.equal(found_index, 3)
  end)

  it("find_last", function()
    local found_last = List.find_last(my_list, function(x)
      return x > 1
    end)
    assert.are.equal(found_last, 5)
  end)

  it("find_last_index", function()
    local found_last_index = List.find_last_index(my_list, function(x)
      return x > 1
    end)
    assert.are.equal(found_last_index, 5)
  end)

  it("flat", function()
    local nested_list = { 1, { 2, 3 }, { 4, { 5, 6 } } }
    local flat_list = List.flat(nested_list)
    assert.are.same(flat_list, { 1, 2, 3, 4, 5, 6 })
  end)

  it("each", function()
    local sum = 0
    List.each(my_list, function(x)
      sum = sum + x
    end)
    assert.are.equal(sum, 15)
  end)

  it("includes", function()
    local has_value = List.includes(my_list, 3)
    assert.is_true(has_value)
  end)

  it("join", function()
    local joined = List.join(my_list, "-")
    assert.are.equal(joined, "1-2-3-4-5")
  end)

  it("keys", function()
    local keys = List.keys(my_list)
    local expected_keys = { 1, 2, 3, 4, 5 }
    for i, k in ipairs(keys) do
      assert.are.equal(k, expected_keys[i])
    end
  end)

  it("last_index_of", function()
    local last_index_of = List.last_index_of(my_list, 2)
    assert.are.equal(last_index_of, 2)
  end)

  it("map", function()
    local mapped_list = List.map(my_list, function(x)
      return x * 2
    end)
    assert.are.same(mapped_list, { 2, 4, 6, 8, 10 })
  end)

  it("add", function()
    local list_copy = { unpack(my_list) }
    local new_list = List.add(list_copy, 6, 7)
    assert.are.equal(#new_list, 7)
    assert.are.same(new_list, { 1, 2, 3, 4, 5, 6, 7 })
  end)

  it("push", function()
    local list_copy = { unpack(my_list) }
    local new_length = List.push(list_copy, 6, 7)
    assert.are.equal(new_length, 7)
    assert.are.same(list_copy, { 1, 2, 3, 4, 5, 6, 7 })
  end)

  it("pop", function()
    local list_copy = { unpack(my_list) }
    local last_element = List.pop(list_copy)
    assert.are.equal(last_element, 5)
    assert.are.same(list_copy, { 1, 2, 3, 4 })
  end)

  it("reduce", function()
    local sum = List.reduce(my_list, function(acc, x)
      return acc + x
    end, 0)
    assert.are.equal(sum, 15)
  end)

  it("reduce_right", function()
    local concatenated = List.reduce_right({ "a", "b", "c" }, function(acc, x)
      return acc .. x
    end, "")
    assert.are.equal(concatenated, "cba")
  end)

  it("reverse", function()
    local reversed_list = List.reverse({ 1, 2, 3, 4, 5 })
    assert.are.same(reversed_list, { 5, 4, 3, 2, 1 })
  end)

  it("shift", function()
    local list_copy = { unpack(my_list) }
    local first_element = List.shift(list_copy)
    assert.are.equal(first_element, 1)
    assert.are.same(list_copy, { 2, 3, 4, 5 })
  end)

  it("slice", function()
    local sliced_list = List.slice(my_list, 2, 4)
    assert.are.same(sliced_list, { 2, 3, 4 })
  end)

  it("some", function()
    local any_even = List.some(my_list, function(x)
      return x % 2 == 0
    end)
    assert.is_true(any_even)
  end)

  it("sort", function()
    local unsorted_list = { 5, 3, 1, 4, 2 }
    local sorted_list = List.sort(unsorted_list)
    assert.are.same(sorted_list, { 1, 2, 3, 4, 5 })
  end)

  it("unshift", function()
    local list_copy = { unpack(my_list) }
    local new_length = List.unshift(list_copy, 0, -1)

    assert.are.equal(new_length, 7)
    assert.are.same(list_copy, { 0, -1, 1, 2, 3, 4, 5 })
  end)

  it("values", function()
    local values = List.values({ 2, 3, 1, 4, 5 })
    local expected_values = { 2, 3, 1, 4, 5 }
    for i, v in ipairs(values) do
      assert.are.equal(v, expected_values[i])
    end
  end)

  it("with", function()
    local modified_list = List.with(my_list, 3, 99)
    assert.are.same(modified_list, { 1, 2, 99, 4, 5 })
  end)
end)
