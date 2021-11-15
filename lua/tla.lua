local Job = require('plenary.job')
local utils = require('tla.utils')
local parser = require('tla.parser')

local M = {}

local config =  {
  java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME')),
  java_opts = { '-XX:+UseParallelGC' },
  tla2tools = vim.api.nvim_get_runtime_file('resources/tla2tools.jar', false)[1]
}

local state = {
  tags_files = {},
  msg_lines = {},
  msg_type = nil,
}

local function on_output(buf, tags_file, tla_file)
  return vim.schedule_wrap(function(err, output)
    if err then
      utils.append_to_buf(buf, { 'Error: ' .. err })
    end
    if output then
      local start_match = parser.parse_msg_start(output)
      if start_match then
        state.msg_type = start_match
      elseif parser.parse_msg_end(output) then
        local tag = parser.parse_msg(state.msg_lines, state.msg_type, tla_file)
        if tag then tags_file:write(tag) end

        utils.append_to_buf(buf, state.msg_lines)
        state.msg_lines = {}
      else
        table.insert(state.msg_lines, output)
      end
    end
  end)
end

local function open_tags_file(tla_file_path)
  local tags_file_path = state.tags_files[tla_file_path] or os.tmpname()
  state.tags_files[tla_file_path] = tags_file_path
  local tags_file = io.open(tags_file_path, 'w')
  vim.opt_global.tags:append(tags_file_path)
  return tags_file
end

local function make_job(tla_file_path, job_args)
  utils.check_filetype_is_tla(tla_file_path)
  local output_buf = utils.get_or_create_output_buf(tla_file_path)
  utils.clear_buf(output_buf)
  utils.focus_output_win(output_buf)

  local command = config.java_executable
  local tags_file = open_tags_file(tla_file_path)

  local args = utils.concat_arrays(config.java_opts, job_args)
  utils.print_command_to_buf(output_buf, command, args)

  local on_result = on_output(output_buf, tags_file, tla_file_path)
  return Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
    on_exit = vim.schedule_wrap(function() tags_file:close() end)
  })
end

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
  make_job(tla_file_path, check_args):start()
end

-- Translate PlusCal into TLA+
M.translate = function()
  local tla_file_path = utils.get_current_file_path()
  local translate_args = {
    '-cp',
    config.tla2tools,
    'pcal.trans',
    tla_file_path
  }
  make_job(tla_file_path, translate_args):start()
end


M.setup = function()
  require('plenary.filetype').add_table({extension = {['tla'] = 'tla'}})
end

return M
