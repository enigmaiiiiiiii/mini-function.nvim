local configs = require('mini-functions.configs')

local M = {}

function M.setup()
  -- configs.init()
  configs.setup()
end

---@class MiniModule
---@field config table<string, any>
---@field attach function(string)

return M
