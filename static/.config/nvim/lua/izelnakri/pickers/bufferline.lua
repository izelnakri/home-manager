-- bufferline.nvim constants.positions_key

-- TODO: move selection position to the current buffer on init

local ActionHistory = {
  state = {},
}

function ActionHistory:get_last_action()
  return self.state[#self.state]
end

-- @param action_key: "delete" | "move_forward" | "move_backward"
function ActionHistory:push(action)
  table.insert(self.state, action)
end

function ActionHistory:pop()
  local last_element = self:get_last_action()

  table.remove(self.state, #self.state)

  return last_element
end

local BufferlineActions = {
  create = function(selection, picker)
    local bufferline = require("bufferline")
    local bufnr = vim.fn.bufadd(selection.path)

    vim.bo[bufnr].buflisted = true
    vim.schedule(function()
      local total_target_element_count = #require("bufferline").get_elements().elements
      local new_entry = vim.tbl_extend("force", selection, { bufnr = bufnr })

      picker.finder.results[#picker.finder.results + 1] = new_entry

      for i = total_target_element_count, selection.index + 1, -1 do
        bufferline.move_to(i, i - 1)

        local entry = picker.finder.results[i - 1]
        entry.index = entry.index + 1

        picker.finder.results[i - 1] = new_entry
        picker.finder.results[i] = entry
      end

      picker:refresh()
    end)
  end,
  delete = function(selection, picker, callback)
    local prompt_buffer_number = picker.prompt_bufnr -- TODO: This has to be taken!
    local old_index = selection.index
    local target_buffer = vim.bo[selection.bufnr]
    if target_buffer.modified == false then
      vim.api.nvim_buf_delete(selection.bufnr, { force = true })

      return picker:delete_selection(function()
        for entry in picker.manager:iter() do
          if entry.index > selection.index then
            entry.index = entry.index - 1
          end
        end

        return callback and callback(old_index)
      end)
    end

    require("telescope.actions.set").select(prompt_buffer_number, "default")

    vim.api.nvim_feedkeys(" bd", "m", false)

    if not target_buffer.modified then
      picker:delete_selection(function()
        for entry in picker.manager:iter() do
          if entry.index > selection.index then
            entry.index = entry.index - 1
          end
        end

        return callback and callback(old_index)
      end)

      require("telescope.builtin").resume()
    end
  end,
  move = function(from_index, to_index, picker)
    require("bufferline").move_to(from_index, to_index)

    if from_index > to_index then
      for entry in picker.manager:iter() do
        if entry.index == from_index then
          entry.index = to_index
          picker.finder.results[to_index] = entry
        elseif entry.index == to_index then
          entry.index = from_index
          picker.finder.results[from_index] = entry
        end
      end
    else
      for entry in picker.manager:iter() do
        if entry.index == to_index then
          entry.index = from_index
          picker.finder.results[from_index] = entry
        elseif entry.index == from_index then
          entry.index = to_index
          picker.finder.results[to_index] = entry
        end
      end
    end

    picker:refresh()
  end,
}

return function() -- NOTE: maybe add opts here
  return function()
    local bufferline = require("bufferline") -- different order = vim.fn.getbufinfo({ buflisted = 1 })
    local pickers = require("telescope.pickers")
    local conf = require("telescope.config").values
    local utils = require("telescope.utils")
    local results = {}

    for index, element in ipairs(bufferline.get_elements().elements) do
      local buffer = vim.fn.getbufinfo(element.path)[1]
      local winid = buffer.windows and buffer.windows[1]
      local window = winid and vim.fn.getwininfo(winid)[1]
      local col = (window and window.wincol) or 0

      table.insert(results, {
        index = index,
        value = buffer.name .. ":" .. buffer.lnum .. ":" .. col,
        bufnr = buffer.bufnr,
        winid = winid,
        path = buffer.name,
        lnum = buffer.lnum,
        col = col,
        ordinal = buffer.name .. ":" .. buffer.lnum,
        display = function(entry)
          local index = tostring(entry.index) .. " - "
          local icon, icon_hl_group = utils.get_devicons(entry.path, false)

          return index .. icon .. " " .. entry.path, { { { #index, #icon + #index + 1 }, icon_hl_group } }
        end,
      })
    end

    return pickers
      :new({
        prompt_title = "Bufferline",
        finder = require("telescope.finders").new_table({
          results = results,
          entry_maker = function(entry)
            return entry
          end,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_buffer_number, map)
          local KEYCODES = require("izelnakri.keycodes")
          local action_set = require("telescope.actions.set")
          local action_state = require("telescope.actions.state")
          local action_utils = require("telescope.actions.utils")

          for i = 1, 9, 1 do
            map({ "i", "n" }, KEYCODES["C_F" .. i], function()
              local picker = action_state.get_current_picker(prompt_buffer_number)
              local target_row
              action_utils.map_entries(prompt_buffer_number, function(entry, _, row)
                if entry.index == i then
                  target_row = row
                end
              end)

              if target_row then
                picker:set_selection(target_row)
                action_set.select(prompt_buffer_number, "default")
              end
            end)
          end

          map({ "i", "n" }, "<C-u>", function()
            local target_action = ActionHistory:get_last_action()
            if not target_action then
              return Utils.notify("Already at the latest change!")
            end

            local picker = action_state.get_current_picker(prompt_buffer_number)
            local action_label = target_action[1]
            if action_label == "delete" then
              BufferlineActions.create(target_action[2], picker)
            elseif action_label == "move_forward" then
              BufferlineActions.move(target_action[3], target_action[2], picker)
            elseif action_label == "move_backward" then
              BufferlineActions.move(target_action[3], target_action[2], picker)
            end

            ActionHistory:pop()
          end)

          map({ "i", "n" }, "<C-]>", function()
            local picker = action_state.get_current_picker(prompt_buffer_number)
            local total_buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
            local current_row_buffer = picker:get_selection()
            local target_index = ((current_row_buffer.index == total_buffer_count) and 1)
              or current_row_buffer.index + 1

            ActionHistory:push({ "move_forward", current_row_buffer.index, target_index })
            BufferlineActions.move(current_row_buffer.index, target_index, picker)
          end)

          map({ "i", "n" }, "<C-[>", function()
            local picker = action_state.get_current_picker(prompt_buffer_number)
            local total_buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
            local current_row_buffer = picker:get_selection()
            local target_index = ((current_row_buffer.index == 1) and total_buffer_count)
              or current_row_buffer.index - 1

            ActionHistory:push({ "move_backward", current_row_buffer.index, target_index })
            BufferlineActions.move(current_row_buffer.index, target_index, picker)
          end)

          map({ "i", "n" }, "<C-d>", function()
            local picker = action_state.get_current_picker(prompt_buffer_number)
            local selection = picker:get_selection()

            BufferlineActions.delete(selection, picker, function(old_index)
              ActionHistory:push({ "delete", selection, old_index })
            end)
          end)

          map({ "n" }, "dd", function()
            local picker = action_state.get_current_picker(prompt_buffer_number)
            local selection = picker:get_selection()

            BufferlineActions.delete(selection, picker, function(old_index)
              ActionHistory:push({ "delete", selection, old_index })
            end)
          end)

          return true
        end,
      })
      :find()
  end
end
