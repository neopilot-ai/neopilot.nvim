---@class neopilot.extensions
local M = {}

setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("neopilot.extensions." .. k)
    return t[k]
  end,
})
