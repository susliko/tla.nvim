
java_executable = 'java' -- todo use JAVA_HOME
java_ops = '-XX:+UseParallelGC' -- todo need to extend with custom
tla2tools = './resources/tla2tools.jar' -- todo  use absolute path

java_command = string.format(' %s -cp %s %s ', java_executable, tla2tools, java_ops)


local function get_check_command(filepath)
  local tla_file = filepath .. '.tla'
  local cfg_file = filepath .. '.cfg'
  local output_file = filepath .. '.out'

  local command_template =' tlc2.TLC %s -tool -modelcheck -coverage 1 -config %s >> %s '

  return java_command .. string.format(command_template, tla_file, cfg_file, output_file)
end

-- Checs file with TLC
local function check(filepath_withot_extencion, extencion)
  if extencion ~= 'tla' and extencion ~= 'cfg' then return end

  local command = get_check_command(filepath_withot_extencion)
  vim.fn.jobstart(command)
end


local function get_translate_command(filepath)
  return java_command .. string.format(' pcal.trans %s ', filepath)
end

-- Translate PlusCal into TLA+
local function translate(filepath, extencion)
  print(filepath, extencion)
  if extencion ~= 'tla' then return end

  local command = get_translate_command(filepath)
  print("Runing", command)
  vim.fn.jobstart(command)
end

return {
  check = check,
  translate = translate
}
