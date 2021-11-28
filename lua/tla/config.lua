local M = {
  java_executable = string.format('%s/bin/java', vim.fn.getenv('JAVA_HOME')),
  java_opts = { '-XX:+UseParallelGC' },
  tla2tools = vim.api.nvim_get_runtime_file('resources/tla2tools.jar', false)[1],
  print_message_type = false
}

return M
