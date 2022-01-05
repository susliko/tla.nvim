local Job = require("plenary.job")
local utils = require("tla.utils")
local parser = require("tla.parser")
local ResultKind = parser.ResultKind

local M = {}

local state = {
	tag_files = {},
	tag_file_contents = {},
}

local function print_parsed_message(outcome, buf)
	if outcome.kind == ResultKind.Unparsed then
		error("Failed to parse some TLC message")
		return
	end
	if outcome.kind == ResultKind.Parsed then
		if outcome.tag then
			table.insert(state.tag_file_contents, outcome.tag)
		end
		if outcome.msg then
			utils.append_to_buf(buf, outcome.msg)
		end
	end
end

local function on_output(buf, tla_file_path, message, config)
	return vim.schedule_wrap(function(err, output)
		if err then
			utils.append_to_buf(buf, { "Error: " .. err })
		end
		if output then
			local start_match = parser.parse_msg_start(output)
			if start_match then
				message.kind = start_match
			elseif parser.parse_msg_end(output) then
				local outcome = parser.parse_msg(message, tla_file_path)
				print_parsed_message(outcome, buf)
				message.lines = {}
				message.kind = {}
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
	local tag_file = io.open(tag_file_path, "w+")
	table.sort(state.tag_file_contents, function(a, b)
		return a:lower() < b:lower()
	end)
	local tags = table.concat(state.tag_file_contents, "")
	tag_file:write(tags)
	tag_file:flush()
	tag_file.close()
	state.tag_file_contents = {}
end

M.make_check_job = function(tla_file_path, job_args, config)
	utils.check_filetype_is_tla(tla_file_path)
	local output_buf = utils.get_or_create_output_buf(tla_file_path)
	utils.clear_buf(output_buf)
	utils.open_output_win(output_buf)

	local command = config.java_executable

	local args = vim.tbl_flatten({ config.java_opts, job_args })
	utils.print_command_to_buf(output_buf, command, args)

	local output_message = {
		lines = {},
		kind = nil,
	}

	local on_result = on_output(output_buf, tla_file_path, output_message, config)
	return Job:new({
		command = command,
		args = args,
		on_stdout = on_result,
		on_error = on_result,
		on_exit = vim.schedule_wrap(function()
			register_tags(tla_file_path)
		end),
	})
end

return M
