-- lua/anchor/telescope.lua: Telescope picker integration.

local anchor_list = require("anchor.list")
local M = {}

function M.picker_current_buffer()
  local success, telescope = pcall(require, "telescope")
  if not success then
    print("Telescope is not installed. Please install telescope to use this feature.")
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local anchors = require("anchor.memory_store").get_anchors()

  if #anchors == 0 then
    print("No anchors found in current buffer")
    return
  end

  pickers
    .new({}, {
      prompt_title = "Buffer Anchors",
      finder = finders.new_table({
        results = anchors,
        entry_maker = function(entry)
          local line_text = vim.fn.getline(entry.row)
          local display_text = string.format("Ln %d: %s", entry.row, line_text)
          return {
            value = entry,
            display = display_text,
            ordinal = display_text,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
        actions.select_default:replace(function(prompt_bufnr)
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.api.nvim_win_set_cursor(0, { selection.value.row, selection.value.col })
            print(string.format("Jumped to line %d", selection.value.row))
          end
        end)
        return true
      end,
    })
    :find()
end

function M.picker_all_buffers()
  local success, telescope = pcall(require, "telescope")
  if not success then
    print("Telescope is not installed. Please install telescope to use this feature.")
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local all_anchors = require("anchor.memory_store").get_all_anchors()

  if #all_anchors == 0 then
    print("No anchors found in any buffer")
    return
  end

  pickers
    .new({}, {
      prompt_title = "All Anchors",
      finder = finders.new_table({
        results = all_anchors,
        entry_maker = function(entry)
          local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          local line_text = ""

          -- Safely get line text if buffer is still valid
          if vim.api.nvim_buf_is_valid(entry.bufnr) then
            local ok, text = pcall(vim.api.nvim_buf_get_lines, entry.bufnr, entry.row - 1, entry.row, false)
            if ok and text[1] then line_text = text[1] end
          end

          local display_text = string.format("%s:%d: %s", filename, entry.row, line_text)
          return {
            value = entry,
            display = display_text,
            ordinal = display_text,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
        actions.select_default:replace(function(prompt_bufnr)
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local anchor = selection.value

            -- Switch to the buffer if it's different and valid
            if vim.api.nvim_buf_is_valid(anchor.bufnr) and anchor.bufnr ~= vim.api.nvim_get_current_buf() then
              vim.api.nvim_set_current_buf(anchor.bufnr)
            end

            -- Jump to position
            vim.api.nvim_win_set_cursor(0, { anchor.row, anchor.col })
            print(
              string.format(
                "Jumped to line %d in %s",
                anchor.row,
                vim.fn.fnamemodify(vim.api.nvim_buf_get_name(anchor.bufnr), ":t")
              )
            )
          end
        end)
        return true
      end,
    })
    :find()
end

-- Show anchors for current buffer only
function M.current_buffer() M.picker_current_buffer() end

-- Show anchors for all buffers
function M.all_buffers() M.picker_all_buffers() end

return M
