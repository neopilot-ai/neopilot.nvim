local Base = require("neopilot.llm_tools.base")

---@class NeopilotLLMTool
local M = setmetatable({}, Base)

M.name = "update_todo_status"

M.description = "Update the status of TODO"

---@type NeopilotLLMToolParam
M.param = {
  type = "table",
  fields = {
    {
      name = "id",
      description = "The ID of the TODO to update",
      type = "string",
    },
    {
      name = "status",
      description = "The status of the TODO to update",
      type = "string",
      choices = { "todo", "doing", "done", "cancelled" },
    },
  },
}

---@type NeopilotLLMToolReturn[]
M.returns = {
  {
    name = "success",
    description = "Whether the TODO was updated successfully",
    type = "boolean",
  },
  {
    name = "error",
    description = "Error message if the TODOs could not be updated",
    type = "string",
    optional = true,
  },
}

M.on_render = function() return {} end

---@type NeopilotLLMToolFunc<{ id: string, status: string }>
function M.func(input, opts)
  local on_complete = opts.on_complete
  local sidebar = require("neopilot").get()
  if not sidebar then return false, "Neopilot sidebar not found" end
  local todos = sidebar.chat_history.todos
  if not todos or #todos == 0 then return false, "No todos found" end
  for _, todo in ipairs(todos) do
    if tostring(todo.id) == tostring(input.id) then
      todo.status = input.status
      break
    end
  end
  sidebar:update_todos(todos)
  if on_complete then
    on_complete(true, nil)
    return nil, nil
  end
  return true, nil
end

return M
