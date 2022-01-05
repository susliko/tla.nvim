local utils = require("tla.utils")

local M = {}

local MessageKind = {
	Coverage = "2772",
	CoverageConstraint = "2778",
	CoverageEnd = "2202",
	CoverageInit = "2773",
	CoverageProperty = "2774",
	CoverageValue = "2221",
	CoverageValueCost = "2775",
	Finished = "2186",
	InvariantViolated = "2110",
	State = "2217",
}
M.MessageKind = MessageKind

local Pattern = {
	MsgStart = "@!@!@STARTMSG (%d+).*",
	MsgEnd = "@!@!@ENDMSG (%d+).*",
	Decl = "<([%a%d]+) line (%d+), col (%d+) .* module (%a+)%s*.*>",
	InvariantViolated = "(Invariant )([%a%d]+)( is violated.)",
	Coverage = ": (%d+):(%d+)",
}

-- Encodes declaration in TLA file
local TlaDecl = {}
function TlaDecl:new(name, module, line, column)
	local a = {
		name = name,
		position = {
			module = module,
			line = line,
			column = column,
		},
	}
	setmetatable(a, { __index = self })
	return a
end

function TlaDecl:to_tag_string(tla_file_path)
	local module_dir = tla_file_path:match("(.*)/.*.tla")
	local module_file = string.format("%s/%s.tla", module_dir, self.position.module)
	return string.format("%s\t%s\tnorm %sG%s|\n", self.name, module_file, self.position.line, self.position.column)
end

function TlaDecl:to_string()
	return "|" .. self.name .. "|"
end

local function parse_coverage(lines)
	local decl_name, line, column, module, distinct, total = string.match(lines[1], Pattern.Decl .. Pattern.Coverage)
	local decl = TlaDecl:new(decl_name, module, line, column)
	return {
		msg = { string.format("%s distinct: %d, total %d", decl:to_string(), distinct, total) },
		decl = decl,
	}
end

local function parse_decl(lines)
	local decl_name, line, column, module = string.match(lines[1], Pattern.Decl)
	local decl = TlaDecl:new(decl_name, module, line, column)
	return { decl = decl }
end

local function parse_state(lines)
	lines[1] = string.gsub(lines[1], Pattern.Decl, "|%1|")
	return { msg = lines }
end

local function parse_invariant_violated(lines)
	lines[1] = string.gsub(lines[1], Pattern.InvariantViolated, "%1|%2|%3")
	return { msg = lines }
end

-- If `str` matches message start pattern, returns message code
M.parse_msg_start = function(str)
	return string.match(str, Pattern.MsgStart)
end

-- If `str` matches message end pattern, returns message code
M.parse_msg_end = function(str)
	return string.match(str, Pattern.MsgEnd)
end

local ResultKind = utils.enum({ "Unparsed", "Parsed", "Skipped" })
M.ResultKind = ResultKind

-- Returns table:
-- {
--   kind = ResultKind.X,
--   msg = { ... }, # optinal array of strings: output useful to the user
--   tag = '...',   # optinal string: entry for the tag file, which powers go to definition
-- }
M.parse_msg = function(message, tla_file_path)
	local result = { kind = ResultKind.Unparsed, msg = {} }
	local function skip()
		result.kind = ResultKind.Skipped
	end
	local function pass()
		result.kind = ResultKind.Parsed
		result.msg = message.lines
	end
	local function update(outcome)
		if outcome then
			result.kind = ResultKind.Parsed
			result.msg = outcome.msg
			if outcome.decl then
				result.tag = outcome.decl:to_tag_string(tla_file_path)
			end
		end
	end

	if message.kind == MessageKind.Coverage or message.kind == MessageKind.CoverageInit then
		update(parse_coverage(message.lines))
	elseif message.kind == MessageKind.CoverageEnd then
		table.insert(message.lines, "")
		pass()
	elseif message.kind == MessageKind.State then
		update(parse_state(message.lines))
	elseif message.kind == MessageKind.CoverageProperty or message.kind == MessageKind.CoverageConstraint then
		update(parse_decl(message.lines))
	elseif message.kind == MessageKind.CoverageValue or message.kind == MessageKind.CoverageValueCost then
		skip()
	elseif message.kind == MessageKind.InvariantViolated then
		update(parse_invariant_violated(message.lines))
	elseif message.kind == MessageKind.Finished then
		table.insert(message.lines, 1, "")
		pass()
	else
		pass()
	end

	return result
end

return M
