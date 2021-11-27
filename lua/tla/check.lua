local Job = require('plenary.job')
local utils = require('tla.utils')
local parser = require('tla.parser')

local M = {}

local state = {
  tag_files = {},
  tag_file_contents = {},
}

local function print_parsed_message(parsed, buf)
  if not parsed then return end
  if parsed.tag then
    table.insert(state.tag_file_contents, parsed.tag)
  else
    utils.append_to_buf(buf, parsed)
  end
end

local function on_output(buf, tla_file, message, config)
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
        print_parsed_message(parsed, buf)
        message.lines = {}; message.type = {}
      else
        table.insert(message.lines, output)
      end
    end
  end)
end

local function register_tags(tla_file_path)
  local tag_file_path = nil
  if state.tag_files[tla_file_path] then
    tag_file_path = state.tag_files[tla_file_path]
  else
    tag_file_path = os.tmpname()
    vim.opt_global.tags:append(tag_file_path)
  end
  state.tag_files[tla_file_path] = tag_file_path
  local tag_file = io.open(tag_file_path, 'w+')
  table.sort(state.tag_file_contents, function (a, b) return a:lower() < b:lower() end)
  local tags = table.concat(state.tag_file_contents, '')
  dump(tag_file_path)
  tag_file:write(tags)
  tag_file:flush()
  tag_file.close()
  state.tag_file_contents = {}
end

M.make_check_job = function(tla_file_path, job_args, config)
  utils.check_filetype_is_tla(tla_file_path)
  local output_buf = utils.get_or_create_output_buf(tla_file_path)
  utils.clear_buf(output_buf)
  utils.focus_output_win(output_buf)

  local command = config.java_executable

  local args = vim.tbl_flatten({config.java_opts, job_args})
  utils.print_command_to_buf(output_buf, command, args)

  local output_message = {
    lines = {},
    type = nil
  }

  local on_result = on_output(output_buf, tla_file_path, output_message, config)
  return Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
    on_exit = vim.schedule_wrap(function() register_tags(tla_file_path) end)
  })
end

return M
