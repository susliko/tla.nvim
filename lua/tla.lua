local Job = require("plenary.job")
local Path = require("plenary.path")
local Filetype = require("plenary.filetype")
local Utils = require("tla.utils")
local Check = require("tla.check")
local Config = require("tla.config")
local Install = require("tla.install")

local M = {}

-- Check TLA+ model in currenct file with TLC
M.check = function()
  local tla_file_path = Utils.get_current_file_path()
  local cfg_file_path = tla_file_path:gsub("%.tla$", ".cfg")
  local check_args = {
    "-cp",
    Config.tla2tools,
    "tlc2.TLC",
    tla_file_path,
    "-tool",
    "-modelcheck",
    "-coverage",
    "1",
	"-workers",
	"auto",
    "-config",
    cfg_file_path,
  }
  vim.inspect(check_args)
  Check.make_check_job(tla_file_path, check_args, Config):start()
end

-- Translate PlusCal in current file into TLA+
M.translate = function()
  local tla_file_path = Utils.get_current_file_path()
  Utils.check_filetype_is_tla(tla_file_path)

  local bufnr = Utils.get_or_create_output_buf(tla_file_path)
  Utils.clear_buf(bufnr)
  Utils.open_output_win(bufnr)

  local command = Config.java_executable

  local translate_args = {
    "-cp",
    Config.tla2tools,
    "pcal.trans",
    tla_file_path,
  }
  local args = vim.tbl_flatten({ Config.java_opts, translate_args })
  Utils.print_command_to_buf(bufnr, command, args)

  local on_result = vim.schedule_wrap(function(err, output)
    if err then
      Utils.append_to_buf(bufnr, { "Error: " .. err })
    end
    if output then
      Utils.append_to_buf(bufnr, { output })
    end
  end)

  Job
      :new({
        command = command,
        args = args,
        on_stdout = on_result,
        on_error = on_result,
      })
      :start()
end

local get_default_java_executable = function()
  java_home = vim.fn.getenv("JAVA_HOME")
  if java_home ~= vim.NIL then
    return Path:new(java_home, "bin", "java").filename
  else
    vim.notify("[tla.nvim] Neither 'java_executable' config nor 'JAVA_HOME' variable are set", vim.log.levels.WARN)
    return nil
  end
end

M.setup = function(user_config)
  Filetype.add_table({ extension = { ["tla"] = "tla" } })

  user_config = user_config or {}
  local config = {}

  if user_config["java_executable"] then
    config.java_executable = Path:new(user_config["java_executable"]).filename
  else
    config.java_executable = get_default_java_executable()
  end

  config.java_opts = user_config["java_opts"] or { "-XX:+UseParallelGC" }
  if user_config["tla2tools"] then
    config.tla2tools = Path:new(user_config["tla2tools"]).filename
  else
    config.tla2tools = Path:new(Utils.tla_nvim_cache_dir, "tla2tools.jar").filename
  end

  if not Path:new(config.tla2tools):exists() then
    Install.install_tla2tools()
  end

  Config = config
end


return M
