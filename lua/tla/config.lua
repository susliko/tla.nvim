local Path = require('plenary.path')
local utils = require('tla.utils')

local M = {
  java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME')),
  java_opts = { '-XX:+UseParallelGC' },
  tla2tools = Path:new(utils.tla_nvim_cache_dir, 'tla2tools.jar').filename,
  print_message_type = false
}

return M
