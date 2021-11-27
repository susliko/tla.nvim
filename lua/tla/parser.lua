local M = {}

local MessageType = {
  CoverageStart = '2201',
  CoverageEnd   = '2202',

  InvariantViolated = '2110';

  Starting = '2185';
  Finished = '2186';

  State = '2217',

  CoverageValue = '2221',

  Coverage      = '2772',
  CoverageInit  = '2773',
  CoverageProperty = '2774',
  CoverageValueCost = '2775',
  CoverageConstraint = '2778',
}

local Pattern = {
  MsgStart = '@!@!@STARTMSG (%d+).*',
  MsgEnd = '@!@!@ENDMSG (%d+).*',
  Step = '<(%a+) line (%d+), col (%d+) .* module (%a+)%s*.*>',
  InvariantViolated = '(Invariant )(%a+)( is violated.)',
  Coverage = ': (%d+):(%d+)',
}

local TlaStep = {}
function TlaStep:new(name, file, line, column)
  local a = {
    name = name,
    position = {
      file = file,
      line = line,
      column = column
    }
  }
  setmetatable(a, { __index = self })
  return a
end

function TlaStep:to_tag_string()
  return string.format(
    '%s\t%s\tnorm %sG%s|\n',
    self.name,
    self.position.file,
    self.position.line,
    self.position.column
  )
end

function TlaStep:to_string()
  return string.format( '|%s|', self.name)
end

local function parse_coverage(message_lines, tla_file)
  local step_name, line, column, module, distinct, total =
    string.match(message_lines[1], Pattern.Step .. Pattern.Coverage)
  local module_dir, _ = tla_file:match('(.*)/(.*).tla')
  local module_file = string.format('%s/%s.tla', module_dir, module)
  local step = TlaStep:new(step_name, module_file, line, column)
  return {
    string.format(
      '%s distinct: %d, total %d',
      step:to_string(),
      distinct,
      total
    ),
    tag = step:to_tag_string()
  }
end

local function parse_tag(lines, tla_file)
  local step_name, line, column, module =
    string.match(lines[1], Pattern.Step)
  local module_dir, _ = tla_file:match('(.*)/(.*).tla')
  local module_file = string.format('%s/%s.tla', module_dir, module)
  local step = TlaStep:new(step_name, module_file, line, column)
  return { tag = step:to_tag_string() }
end

local function parse_state(message_lines)
  message_lines[1] = string.gsub(message_lines[1], Pattern.Step, '|%1|')
  return message_lines
end

local function parse_invariant_violated(message_lines)
  message_lines[1] = string.gsub(
    message_lines[1],
    Pattern.InvariantViolated,
    '%1|%2|%3'
  )
  return message_lines
end

M.parse_msg_start = function(str) return string.match(str, Pattern.MsgStart) end
M.parse_msg_end = function(str) return string.match(str, Pattern.MsgEnd) end

-- returns a table of lines than will be added to output buffer
-- table may have optional `tag` field
M.parse_msg = function(message, tla_file)
  local parsed = nil

  if (message.type == MessageType.Coverage or
      message.type == MessageType.CoverageInit) then
    parsed = parse_coverage(message.lines, tla_file)

  elseif message.type == MessageType.CoverageEnd then
    table.insert(message.lines, '')
    parsed = message.lines

  elseif (message.type == MessageType.Finished or
          message.type == MessageType.Starting) then
    table.insert(message.lines, 1, '')
    parsed = message.lines

  elseif message.type == MessageType.State then
    parsed = parse_state(message.lines)

  elseif (message.type == MessageType.CoverageProperty or
          message.type == MessageType.CoverageConstraint) then
    parsed = parse_tag(message.lines, tla_file)

  elseif message.type == MessageType.InvariantViolated then
    parsed = parse_invariant_violated(message.lines)

  elseif (message.type == MessageType.CoverageValue or
          message.type == MessageType.CoverageValueCost) then
    parsed = nil

  else parsed = message.lines
  end

  return parsed
end

return M

