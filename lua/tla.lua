local Job = require'plenary.job'

-- TODO make configurable opts
local java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME'))
local java_opts = '-XX:+UseParallelGC' 
local tla2tools = './resources/tla2tools.jar' 
local java_command = string.format("%s -cp %s %s", java_executable, tla2tools, java_opts)

local function make_check_job(tla_file_path, on_result)
  local cfg_file_path = tla_file_path:gsub("%.tla$", ".cfg")
  return Job:new({
    command = java_executable,
    args = { 
      "-cp",
      tla2tools,
      java_opts,
      "tlc2.TLC", 
      tla_file_path,
      "-tool",
      "-modelcheck",
      "-coverage",
      "1",
      "-config", 
      cfg_file_path,
    },
    cwd = vim.fn.getcwd(),
    on_stdout = on_result,
    on_error = on_result,
  })
end

-- Check TLA+ model in currenct file with TLC
local function check()
  local filepath = vim.api.nvim_buf_get_name(0)
  local filetype = require'plenary.filetype'.detect_from_extension(filepath) 
  if filetype ~= "tla" then
    print("Can run only on tla files")
  else
    local output_buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_command('vsp')
    vim.api.nvim_win_set_buf(win, output_buf)
    vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { "Checking" })
    local on_result = vim.schedule_wrap(function(err, output)
      vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { output })
    end)
    local check_job = make_check_job(filepath, on_result)
    check_job:start()
  end
end


local function get_translate_command(filepath)
  return java_command .. string.format(' pcal.trans %s ', filepath)
end

-- Translate PlusCal into TLA+
local function translate(filepath, extension)
  print(filepath, extension)
  if extension ~= 'tla' then return end

  local command = get_translate_command(filepath)
  print("Runing", command)
  vim.fn.jobstart(command)
end

return {
  check = check,
  translate = translate,
}
