local configs = require('mini-functions.configs')
local M = {}

local auto_save_group = vim.api.nvim_create_augroup('auto_save', { clear = true })

local global_vars = {}

local function set_buf_var(buf, name, value)
  if buf == nil then
    global_vars[name] = value
  else
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_set_var(buf, 'autosave_' .. name, value) end
  end
end

local function get_buf_var(buf, name)

  if buf == nil then return global_vars[name] end

  local success, mod = pcall(vim.api.nvim_buf_get_var, buf, 'autosave_' .. name)
  return success and mod or nil
end

local debounce = function(func, duration)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    if not get_buf_var(buf, 'queued') then
      vim.defer_fn(function()
        set_buf_var(buf, 'queued', false)
        func(buf)
      end, duration)
      set_buf_var(buf, 'queued', true)
    end
  end
end

local save = function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= '' then
    return
  end
  if not vim.api.nvim_get_option_value("modified", { buf = buf }) then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_command("silent! update")
  end)
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local file_name = string.match(buf_name, "/([^/]+)$")
  local message = string.format('"%s" auto written at %s', file_name, os.date("%H:%M:%S"))
  print(message)
end

---@type number
local delay = configs.get_module('auto_save').delay
local debounced_save = debounce(save, delay)

local auto_save = function(buf)
  local config = configs.get_module('auto_save')
  vim.api.nvim_create_autocmd(
    config.trigger_events,
    {
      group = auto_save_group,
      callback = debounced_save,
    }
)
end

M.attach = function()
  auto_save()
end

M.detach = function() vim.api.nvim_clear_autocmds({ group = auto_save_group }) end

return M
