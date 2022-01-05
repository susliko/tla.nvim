local p = require("tla.parser")
local eq = assert.are.same

describe("tlc output parser should detect message bounds:", function()
	local MessageStart = "@!@!@STARTMSG 42:0 @!@!@"
	local MessageEnd = "@!@!@ENDMSG 42:0 @!@!@"
	it("start", function()
		eq("42", p.parse_msg_start(MessageStart))
	end)

	it("end", function()
		eq("42", p.parse_msg_end(MessageEnd))
	end)
end)

describe("tlc output parser should parse message:", function()
	local function mk_msg(kind, lines)
		return { kind = kind, lines = lines }
	end
	local Message = {
		Coverage = mk_msg(
			p.MessageKind.Coverage,
			{ "<Step1 line 56, col 1 to line 56, col 10 of module Module>: 5:35" }
		),
		CoverageConstraint = mk_msg(p.MessageKind.CoverageConstraint, { "TODO" }),
		CoverageEnd = mk_msg(p.MessageKind.CoverageEnd, { "End of statistics." }),
		CoverageInit = mk_msg(
			p.MessageKind.CoverageInit,
			{ "<Init line 36, col 1 to line 36, col 4 of module Module>: 2:2" }
		),
		CoverageProperty = mk_msg(
			p.MessageKind.CoverageProperty,
			{ "<TypeOK line 34, col 1 to line 34, col 6 of module Module>" }
		),
		CoverageValue = mk_msg(
			p.MessageKind.CoverageValue,
			{ "||||||line 26, col 27 to line 26, col 27 of module Module: 14" }
		),
		CovarageValueCost = mk_msg(p.MessageKind.CovarageValueCost, { "TODO" }),
		Finished = mk_msg(p.MessageKind.Finished, { "Finished in 1000ms at (1970-00-00 00:00:00)" }),
		InvariantViolated = mk_msg(p.MessageKind.InvariantViolated, { "Invariant NotSolved is violated." }),
		State = mk_msg(
			p.MessageKind.State,
			{ "2: <Step1 line 56, col 16 to line 56, col 63 of module Module>", "contents = [j1 |-> 0, j2 |-> 5]", "" }
		),
		Unknown = mk_msg("UnknownCode", { "unknown text" }),
	}

	local function msg_ok(name, input, output_msg)
		it(name .. ".message", function()
			local res = p.parse_msg(input, "")
			eq(p.ResultKind.Parsed, res.kind)
			eq(output_msg, res.msg)
		end)
	end
	local function tag_ok(name, input, tla_file_path, output_tag)
		it(name .. ".tag", function()
			local res = p.parse_msg(input, tla_file_path)
			eq(p.ResultKind.Parsed, res.kind)
			eq(output_tag, res.tag)
		end)
	end
	local function skip_ok(name, input)
		it(name .. ".skip", function()
			local res = p.parse_msg(input, "")
			eq(p.ResultKind.Skipped, res.kind)
		end)
	end

	msg_ok("Coverage", Message.Coverage, { "|Step1| distinct: 5, total 35" })
	tag_ok("Coverage", Message.Coverage, "/path/to/file.tla", "Step1\t/path/to/Module.tla\tnorm 56G1|\n")

	msg_ok("CoverageEnd", Message.CoverageEnd, { "End of statistics.", "" })

	msg_ok("CoverageInit", Message.CoverageInit, { "|Init| distinct: 2, total 2" })
	tag_ok("CoverageInit", Message.CoverageInit, "/path/to/file.tla", "Init\t/path/to/Module.tla\tnorm 36G1|\n")

	tag_ok(
		"CoverageProperty",
		Message.CoverageProperty,
		"/path/to/file.tla",
		"TypeOK\t/path/to/Module.tla\tnorm 34G1|\n"
	)

	skip_ok("CoverageValue", Message.CoverageValue)

	msg_ok("Finished", Message.Finished, { "", "Finished in 1000ms at (1970-00-00 00:00:00)" })

	msg_ok("InvariantViolated", Message.InvariantViolated, { "Invariant |NotSolved| is violated." })

	msg_ok("State", Message.State, { "2: |Step1|", "contents = [j1 |-> 0, j2 |-> 5]", "" })

	msg_ok("Unknown", Message.Unknown, { "unknown text" })
end)
