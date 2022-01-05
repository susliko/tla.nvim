local Path = require("plenary.path")
local utils = require("tla.utils")

local config = {
	java_executable = Path:new(vim.fn.getenv("JAVA_HOME"), "bin", "java").filename,
	java_opts = { "-XX:+UseParallelGC" },
	tla2tools = Path:new(utils.tla_nvim_cache_dir, "tla2tools.jar").filename,
}

return config
