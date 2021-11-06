local Job = require'plenary.job'

-- TODO make configurable opts
local java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME'))
local java_opts = '-XX:+UseParallelGC' 
local tla2tools = './resources/tla2tools.jar' 
local java_command = string.format('%s -cp %s %s', java_executable, tla2tools, java_opts)
local output_bufs = {}

local function get_file_path() 
  return vim.api.nvim_buf_get_name(0):gsub('^%s+', ''):gsub('%s+$', '')
end

local function check_file_type(filepath) 
  local file_type = require'plenary.filetype'.detect_from_extension(filepath)
  if file_type ~= 'tla' then
    error('Can run only on TLA files')
  end
end 

local function make_check_job(tla_file_path, on_result)
  local cfg_file_path = tla_file_path:gsub('%.tla$', '.cfg')
  return Job:new({
    command = java_executable,
    args = { 
      '-cp',
      tla2tools,
      java_opts,
      'tlc2.TLC', 
      tla_file_path,
      '-tool',
      '-modelcheck',
      '-coverage',
      '1',
      '-config', 
      cfg_file_path,
    },
    cwd = vim.fn.getcwd(),
    on_stdout = on_result,
    on_error = on_result,
  })
end

local function get_or_create_output_buf(filepath)
  local output_buf = output_bufs[filepath]
  if output_buf == nil then 
    output_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(output_buf, filepath .. ' ')
    output_bufs[filepath] = output_buf
  end
  return output_buf
end

local function focus_output_win(output_buf)
  local output_wins = vim.api.nvim_eval(string.format('win_findbuf(%d)', output_buf))
  if #output_wins == 0 then
    vim.api.nvim_command('vsp')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, output_buf)
  else
    vim.api.nvim_eval(string.format('win_gotoid(%d)', output_wins[1]))
  end
end 

-- Check TLA+ model in currenct file with TLC
local function check()
  local filepath = get_file_path()
  check_file_type(filepath)
  local output_buf = get_or_create_output_buf(filepath)
  focus_output_win(output_buf)

  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { 'Checking' })
  local on_result = vim.schedule_wrap(function(err, output)
    vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { output })
  end)
  local check_job = make_check_job(filepath, on_result)
  check_job:start()
end


-- Translate PlusCal into TLA+
local function translate()
  local filepath = get_file_path()
  check_file_type(filepath)

  local output_buf = get_or_create_output_buf(filepath)
  print(output_buf)
  focus_output_win(output_buf)
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { 'Translating +CAL to TLA+' })
  local on_result = vim.schedule_wrap(function(err, output)
    vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { output })
  end)
  Job:new({
    command = java_executable,
    args = { 
      '-cp',
      tla2tools,
      java_opts,
      'pcal.trans',
      filepath
    },
    on_stdout = on_result,
    on_error = on_result,
  }):start()
end


return {
  check = check,
  translate = translate,
}
