local Job = require'plenary.job'

local config =  {
  java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME')),
  java_opts = { '-XX:+UseParallelGC' },
  tla2tools = vim.api.nvim__get_runtime({ 'resources/tla2tools.jar' }, false, {})[1]
}

local tag_files = {}

local function concat_arrays(a, b)
    a = vim.deepcopy(a)
    for i=1,#b do
        a[#a+1] = b[i]
    end
    return a
end

local function get_file_path()
  return vim.api.nvim_buf_get_name(0):gsub('^%s+', ''):gsub('%s+$', '')
end

local function check_file_type(filepath)
  local file_type = require'plenary.filetype'.detect_from_extension(filepath)
  if file_type ~= 'tla' then
    error('Can run only on TLA files')
  end
end

local function append_to_buf(buf, lines)
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

local MessageType = {
  State = '2217',
  CoverageInit = '2773',
  Coverage = '2772',
  CoverageValue = '2221',
}


local message = { }
local message_type = nil

local coverage_pattern = '<(%a+) line (%d+), col (%d+) .* module (%a+)>: (%d+):(%d+)'

local function parse_coverage(msg, tags_file, tla_file)
  local action, line, column, module, distinct, total = string.match(msg[1], coverage_pattern)
  local tag = string.format('%s\t%s\tnorm %sG%s|\n', action, tla_file, line, column)
  tags_file:write(tag)
  dump(tag)
  dump(action, line, column, module, distinct, total)
end


local start_message_pattern = '@!@!@STARTMSG (%d+).*'
local end_message_pattern = '@!@!@ENDMSG (%d+).*'

local function parse_message(msg, msg_type, buf, tags_file, tla_file)
  if msg_type == MessageType.Coverage then
    parse_coverage(msg, tags_file, tla_file)
  end
  append_to_buf(buf, msg)
  append_to_buf(buf, { message_type })
end

local function get_output_handler(buf, tags_file, tla_file)
  return vim.schedule_wrap(function(err, output)
    if err ~= nil then
      append_to_buf(buf, { 'Error: ' .. err })
    end
    if output ~= nil then
      local start_match = string.match(output, start_message_pattern)
      local end_match = string.match(output, end_message_pattern)
      if start_match ~= nil then
	message_type = start_match
      elseif end_match ~= nil then
	-- todo check types equal
	parse_message(message, message_type, buf, tags_file, tla_file)
	message = {}
      else
	table.insert(message, output)
      end
    end
  end)
end

local function print_command(output_buf, command, args)
  local args_str = table.concat(args, ' ')
  append_to_buf(output_buf, { 'Excuting command:', command ..  args_str, '' })
end

local function make_check_job(tla_file_path, output_buf)
  local command = config.java_executable
  local cfg_file_path = tla_file_path:gsub('%.tla$', '.cfg')

  local tags_file_path = tag_files[tla_file_path] or os.tmpname()
  tag_files[tla_file_path] = tags_file_path


  local tags_file = io.open(tags_file_path, 'w')
  tags_file:write('world')
  dump(tags_file_path)
  vim.opt_global.tags:append(tags_file_path)
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
  local args = concat_arrays(config.java_opts, check_args)
  print_command(output_buf, command, args)

  local on_result = get_output_handler(output_buf, tags_file, tla_file_path)
  return Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
    on_exit = vim.schedule_wrap(function() tags_file:close() end)
  })
end

local function get_or_create_output_buf(filepath)
  local buf_name = filepath .. ' '
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if buf_name == vim.api.nvim_buf_get_name(buf) then
      return buf
    end
  end

  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(output_buf, buf_name)

  return output_buf
end

local function focus_output_win(output_buf)
  local output_wins = vim.fn.win_findbuf(output_buf)
  if #output_wins == 0 then
    vim.api.nvim_command('vsp')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, output_buf)
  else
    vim.fn.win_gotoid(output_wins[1])
  end
end

-- Check TLA+ model in currenct file with TLC
local function check()
  local filepath = get_file_path()
  check_file_type(filepath)
  local output_buf = get_or_create_output_buf(filepath)
  focus_output_win(output_buf)

  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { 'Checkig' })

  make_check_job(filepath, output_buf):start()
end


-- Translate PlusCal into TLA+
local function translate()
  local filepath = get_file_path()
  check_file_type(filepath)

  local output_buf = get_or_create_output_buf(filepath)
  focus_output_win(output_buf)
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { 'Translating +CAL to TLA+' })

  local command = config.java_executable
  local translate_args = {
    '-cp',
    config.tla2tools,
    'pcal.trans',
    filepath
  }
  local args = concat_arrays(config.java_opts, translate_args)
  print_command(output_buf, command, args)

  local on_result = get_output_handler(output_buf)
  Job:new({
    command = command,
    args = args,
    on_stdout = on_result,
    on_error = on_result,
  }):start()
end


return {
  check = check,
  translate = translate,
}
