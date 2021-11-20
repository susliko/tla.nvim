local Job = require('plenary.job')
local utils = require('tla.utils')
local parser = require('tla.parser')

local M = {}

local state = {
  tags_files = {},
}

local function print_parsed_message(parsed, buf, tags_file)
  if not parsed then return end
  if parsed.tag then
    tags_file:write(parsed.tag)
    parsed.tag = nil
  end
  utils.append_to_buf(buf, parsed)
end

local function on_output(buf, tags_file, tla_file, message, config)
  return vim.schedule_wrap(function(err, output)
    if err then
      utils.append_to_buf(buf, { 'Error: ' .. err })
    end
    if output then
      local start_match = parser.parse_msg_start(output)
      if start_match then
        message.type = start_match
      elseif parser.parse_msg_end(output) then
        -- to be able to see which types need to add to parser
        if config.print_message_type then
          utils.append_to_buf(buf, {
            '_____',
            message.type,
          })
        end

        local parsed = parser.parse_msg(message, tla_file)
        print_parsed_message(parsed, buf, tags_file)
        message.lines = {}; message.type = {}
      else
        table.insert(message.lines, output)
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

M.make_check_job = function(tla_file_path, job_args, config)
  utils.check_filetype_is_tla(tla_file_path)
  local output_buf = utils.get_or_create_output_buf(tla_file_path)
  utils.clear_buf(output_buf)
  utils.focus_output_win(output_buf)

  local command = config.java_executable
  local tags_file = open_tags_file(tla_file_path)

  local args = utils.concat_arrays(config.java_opts, job_args)
  utils.print_command_to_buf(output_buf, command, args)

  local output_message = {
    lines = {},
    type = nil
  }

  local on_result = on_output(output_buf, tags_file, tla_file_path, output_message, config)
  return Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
    on_exit = vim.schedule_wrap(function() tags_file:close() end)
  })
end

return M
