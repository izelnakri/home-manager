---@class Buffer
---@field bufnr number Buffer number.
---@field changed 0|1 1 if the buffer is modified.
---@field changedtick number Number of changes made to the buffer.
---@field command 0|1 1 if the buffer belongs to the command-line window |cmdwin|
---@field hidden 0|1 1 if the buffer is hidden.
---@field lastused number Timestamp in seconds, like |localtime()|, when the buffer was last used.
---@field linecount number Number of lines in the buffer (only valid when loaded)
---@field listed 0|1  1 if the buffer is listed.
---@field lnum number Line number when buffer opened in window. It is NOT the last known cursor position.
---@field loaded 0|1 1 if the buffer is loaded.
---@field name string Full path to the file in the buffer.
---@field signs vim.fn.sign[] List of signs placed in the buffer. Sign{id, lnum, name}
---@field variables table<string,any> Buffer-local variables
---@field windows number[] List of winids that display this buffer

---@class BufferQueryOptions
---@field bufnr? number Buffer number.
---@field changed? 0|1 1 if the buffer is modified.
---@field changedtick? number of changes made to the buffer.
---@field command? 0|1 1 if the buffer belongs to the command-line window |cmdwin|
---@field hidden? 0|1 1 if the buffer is hidden.
---@field lastused? number rTimestamp in seconds, like |localtime()|, when the buffer was last used.
---@field linecount? number Number of lines in the buffer (only valid when loaded)
---@field listed? 0|1  1 if the buffer is listed.
---@field lnum? number Line number when buffer opened in window. It is NOT the last known cursor position.
---@field loaded? 0|1 1 if the buffer is loaded.
---@field name? string Full path to the file in the buffer.
---@field signs? vim.fn.sign[] List of signs placed in the buffer. Sign{id, lnum, name}
---@field variables? table<string,any> Buffer-local variables
---@field windows? number[] List of winids that display this buffer

Buffer = {}

-- TODO: Test Buffer:create() with path on save does it replace content?

---@param object Buffer
---@param expression BufferQueryOptions
---@return boolean
local match = function(object, expression)
  local excluded_buffer_keys_for_now = { "signs", "variables", "windows" }
  return Object.keys(expression):all(function(key)
    if List.includes(excluded_buffer_keys_for_now, key) then
      return true
    end

    return object[key] == expression[key]
  end)
end

---@param buffer_reference? number | Buffer
---@return number
local get_bufnr = function(buffer_reference)
  if buffer_reference == nil or buffer_reference == 0 then
    return vim.api.nvim_get_current_buf()
  elseif type(buffer_reference) == "number" then
    return buffer_reference
  end

  return buffer_reference.bufnr
end

---@param bufnr? number
---@return Buffer
local getbufinfo = function(bufnr)
  if bufnr == nil or bufnr == 0 then
    return vim.fn.getbufinfo(vim.api.nvim_get_current_buf())
  end

  return vim.fn.getbufinfo(bufnr) --[[@as Buffer]]
end

---@param opts Buffer Buffer options
---@return Buffer
function Buffer:new(opts)
  self.__index = self

  return setmetatable(Object.assign({}, opts), self)
end

---@param bufnr number | number[] Buffer number
---@return Buffer | Buffer[]
function Buffer.peek(bufnr)
  if bufnr == nil or bufnr == 0 then
    return getbufinfo()[1] --[[@as Buffer]]
  elseif type(bufnr) == "number" then
    return getbufinfo(bufnr)[1] --[[@as Buffer]]
  end

  return List.map(bufnr, function(target_bufnr)
    local buffer = getbufinfo(target_bufnr)[1]
    if Object.is_empty(buffer) then
      return error(
        "Buffer.peek(bufnr) only accepts valid buffer references. Bufnr " .. target_bufnr .. "doesn't exist!"
      )
    end

    return buffer
  end)
end

---@param opts BufferQueryOptions
---@return Buffer[]
function Buffer.peek_all(opts)
  if opts == nil then
    local all_buffer_numbers = vim.api.nvim_list_bufs()
    return List.map(all_buffer_numbers, function(bufnr)
      return getbufinfo(bufnr)[1]
    end)
  elseif opts.bufnr then
    local buffer = getbufinfo(opts.bufnr)[1] --[[@as Buffer]]
    if match(buffer, opts) then
      return { buffer }
    else
      return {}
    end
  end

  local all_buffer_numbers = vim.api.nvim_list_bufs()
  return List.reduce(all_buffer_numbers, function(result, bufnr)
    local buffer = getbufinfo(bufnr)[1] --[[@as Buffer]]
    if match(buffer, opts) then
      return List.add(result, buffer)
    end

    return result
  end, {})
end

---@param opts BufferQueryOptions
---@return Buffer | nil
function Buffer.peek_by(opts)
  if opts == nil then
    return nil
  end

  local all_buffers = List.map(vim.api.nvim_list_bufs(), function(bufnr)
    return getbufinfo(bufnr)[1]
  end)
  return List.find(all_buffers, function(buffer)
    return match(buffer, opts)
  end)
end

---@class BufferCreateOptions
---@field scratch boolean
---@field listed? boolean
---@field name? string I dont know if this is good yet
---@field linecount? number I dont know if this is good yet
---@field lnum? number I dont know if this is good yet
---@field variables? table I dont know if this is good yet

---@param opts BufferCreateOptions
---@return Buffer | 0
function Buffer.create(opts)
  opts = opts or {}
  local listed = opts.listed or true
  local scratch_buffer = not not opts.name

  -- TODO: Do the set_name magic

  return vim.api.nvim_create_buf(listed, scratch_buffer)
end

---@param buffer_reference number | Buffer
---@param new_name string
function Buffer.set_name(buffer_reference, new_name)
  local bufnr = get_bufnr(buffer_reference)

  vim.api.nvim_buf_set_name(bufnr, new_name) -- TODO: This doesnt change the contents?!

  -- nvim_buf_get_text({buffer}, {start_row}, {start_col}, {end_row}, {end_col},
  --                   {opts})
  -- NOTE: Should create a prompt if there is existing content and existing file?

  return Buffer.peek(bufnr)
end

---@param buffer_reference number | Buffer
---@param opts { force: boolean, unload: boolean }
function Buffer.delete(buffer_reference, opts)
  return vim.api.nvim_buf_delete(get_bufnr(buffer_reference), opts)
end

---@param buffer_reference? number | Buffer Bufnr or reference Buffer
---@param opts? table Extra options: start_row, start_col, end_row, end_col
function Buffer.get_text(buffer_reference, opts)
  opts = opts or {}
  local bufnr = get_bufnr(buffer_reference)
  local end_row = opts.end_row or (Buffer.peek(bufnr).linecount - 1)

  return vim.api.nvim_buf_get_text(
    bufnr,
    opts.start_row or 0,
    opts.start_col or 0,
    end_row,
    opts.end_col or 0,
    opts.opts or {}
  )
end

function Buffer.get_line(buffer_reference, line_number)
  local bufnr = get_bufnr(buffer_reference)

  return vim.api.nvim_buf_get_text(bufnr, line_number - 1, 0, line_number, 0, {})[1]
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@param replacement string | string[]
---@param opts? table Extra options: start_row, start_col, end_row, end_col
function Buffer.set_text(buffer_reference, replacement, opts)
  opts = opts or {}
  local bufnr = get_bufnr(buffer_reference)
  local target_replacement = (type(replacement) == "string" and { replacement }) or replacement --[[@as string[] ]]

  if opts.end_col == nil then
    List.unshift(target_replacement, "")
  end

  return vim.api.nvim_buf_set_text(
    bufnr,
    opts.start_row or -1,
    opts.start_col or -1,
    opts.end_row or -1,
    opts.end_col or -1,
    target_replacement
  )
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return table List of changes as objects of { col, coladd, lnum }, last element is changedtick
function Buffer.get_change_list(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)

  return vim.fn.getchangelist(bufnr)
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return boolean
function Buffer.exists(buffer_reference)
  if type(buffer_reference) == "number" then
    return Buffer.peek(buffer_reference) ~= nil
  end

  return Buffer.peek(buffer_reference.bufnr) ~= nil
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return boolean
function Buffer.is_current(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)

  return vim.api.nvim_get_current_buf() == bufnr
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return Buffer
function Buffer.set_current(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)

  vim.api.nvim_set_current_buf(bufnr)

  return Buffer.peek(bufnr)
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return Buffer
function Buffer.list(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)
  vim.bo[bufnr].buflisted = true

  return Buffer.peek(bufnr)
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
---@return Buffer
function Buffer.unlist(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)
  vim.bo[bufnr].buflisted = false

  return Buffer.peek(bufnr)
end

---@param buffer_reference number | Buffer Bufnr or reference Buffer
function Buffer.load(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)

  return vim.fn.bufload(bufnr)
end

---@param buffer_reference number | Buffer
---@param opts { force?: boolean }
function Buffer.unload(buffer_reference, opts)
  local bufnr = get_bufnr(buffer_reference)

  if opts and opts.force then
    return vim.cmd("bunload! " .. tostring(bufnr))
  end

  return vim.cmd("bunload " .. tostring(bufnr))
end

local get_edit_prefix = function(options)
  if options == nil then
    return ""
  elseif options.lnum == -1 then
    return "+"
  elseif options.lnum then
    return "+" .. options.lnum
  elseif options.search then
    return "+/" .. String.replace_all(options.search, " ", "\\ ")
  end

  return ""
end

local get_edit_path = function(buffer_reference)
  if type(buffer_reference) == "string" then
    return buffer_reference
  elseif type(buffer_reference) == "number" then
    return Buffer.peek_all({ listed = 1 })[buffer_reference].name
  end

  return buffer_reference.name
end

---@class BufferEditOptions
---@field lnum integer
---@field search string
---@field force boolean
-- NOTE: Maybe add col field in th future

---@param buffer_reference string | number | Buffer
---@param options? BufferEditOptions
---@return Buffer Returns the target buffer
function Buffer.edit(buffer_reference, options)
  if options and options.force then
    vim.cmd("e! " .. get_edit_prefix(options) .. " " .. get_edit_path(buffer_reference))
  else
    vim.cmd("e " .. get_edit_prefix(options) .. " " .. get_edit_path(buffer_reference))
  end

  return Buffer.peek(0)
end

---@param buffer_reference number | Buffer
---@return Buffer? Returns the fresh buffer_reference
function Buffer.save(buffer_reference)
  local bufnr = get_bufnr(buffer_reference)

  local current_buffer = Buffer.peek(0)
  local target_buffer = Buffer.peek(bufnr)
  if not target_buffer then
    return error("Buffer.save($bufnr) $bufnr " .. tostring(bufnr) .. " doesn't exist! in registered buffers")
  end

  Buffer.set_current(target_buffer)
  vim.cmd("w ++p")

  if current_buffer.bufnr ~= target_buffer.bufnr then
    Buffer.set_current(current_buffer)
  end

  return target_buffer
end

---@param buffer_reference number | Buffer
---@return any
function Buffer.call(buffer_reference, func)
  if type(buffer_reference) == "number" then
    return vim.api.nvim_buf_call(buffer_reference, func)
  end

  return vim.api.nvim_buf_call(buffer_reference.bufnr, func) -- NOTE: check if it switches back to the old current buffer
end

-- TODO: See |prompt-buffer|

-- @param window number | Buffer Buffer scope reference for options
-- function Buffer.get_options(buffer_reference)
--
-- end

return Buffer
