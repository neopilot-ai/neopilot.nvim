-- UI for handling lists and items

local M = {}

local lists = {}

--- Add a new list
---@param list_name string Name of the new list
function M.add_list(list_name)
  if not lists[list_name] then
    lists[list_name] = {}
    print("List created: " .. list_name)
  else
    print("List already exists: " .. list_name)
  end
end

--- Add an item to a list
---@param list_name string Name of the list
---@param item string Item to add
function M.add_item_to_list(list_name, item)
  if lists[list_name] then
    table.insert(lists[list_name], item)
    print("Item added to list " .. list_name .. ": " .. item)
  else
    print("List does not exist: " .. list_name)
  end
end

-- Example: Adding lists and items through key mappings
function M.setup_keymaps()
  vim.keymap.set("n", "<leader>al", function()
    local list_name = vim.fn.input("List name: ")
    if list_name ~= "" then M.add_list(list_name) end
  end, { desc = "Add List" })

  vim.keymap.set("n", "<leader>ai", function()
    local list_name = vim.fn.input("List name: ")
    if list_name ~= "" then
      local item = vim.fn.input("Item: ")
      if item ~= "" then M.add_item_to_list(list_name, item) end
    end
  end, { desc = "Add Item to List" })
end

return M
