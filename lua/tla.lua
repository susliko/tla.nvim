local Job = require('plenary.job')
local utils = require('tla.utils')
local check = require('tla.check')
local config = require('tla.config')

local M = {}

-- Check TLA+ model in currenct file with TLC
M.check = function()
  local tla_file_path = utils.get_current_file_path()
  local cfg_file_path = tla_file_path:gsub('%.tla$', '.cfg')
  local check_args = {
    '-cp',
    config.tla2tools,
    'tlc2.TLC',
    tla_file_path,
    '-tool',
    '-modelcheck',
    '-coverage',
    '1',
    '-config',
    cfg_file_path,
  }
  check.make_check_job(tla_file_path, check_args, config):start()
end

-- Translate PlusCal in current file into TLA+
M.translate = function()
  local tla_file_path = utils.get_current_file_path()
  utils.check_filetype_is_tla(tla_file_path)

  local bufnr = utils.get_or_create_output_buf(tla_file_path)
  utils.clear_buf(bufnr)
  utils.open_output_win(bufnr)

  local command = config.java_executable

  local translate_args = {
    '-cp',
    config.tla2tools,
    'pcal.trans',
    tla_file_path
  }
  local args = vim.tbl_flatten({config.java_opts, translate_args})
  utils.print_command_to_buf(bufnr, command, args)

  local on_result = vim.schedule_wrap(function(err, output)
    if err then
      utils.append_to_buf(bufnr, { 'Error: ' .. err })
    end
    if output then
      utils.append_to_buf(bufnr, { output })
    end
  end)

  Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
  }):start()
end


M.setup = function()
  require('plenary.filetype').add_table({extension = {['tla'] = 'tla'}})
end

return M

