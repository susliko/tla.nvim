local function get_check_command()
  local resources = './resources/'

  local tla2tools = resources .. 'tla2tools.jar'
  local tla_file = resources .. 'simple.spec/simple.tla'
  local cfg_file = resources .. 'simple.spec/simple.cfg'
  local output_file = resources .. 'simple.spec/simple.out'

  local command_template ='java -cp %s -XX:+UseParallelGC tlc2.TLC %s -tool -modelcheck -coverage 1 -config %s >> %s'

  return string.format(command_template, tla2tools, tla_file, cfg_file, output_file)
end

local function check()
  local command = get_check_command()
  vim.fn.jobstart(command)

return {
  check=check
}
