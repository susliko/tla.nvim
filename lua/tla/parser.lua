local M = {}

local MessageType = {
  State = '2217',
  CoverageInit = '2773',
  Coverage = '2772',
  CoverageValue = '2221',
}

local Pattern = {
  MsgStart = '@!@!@STARTMSG (%d+).*',
  MsgEnd = '@!@!@ENDMSG (%d+).*',
  Coverage = '<(%a+) line (%d+), col (%d+) .* module (%a+)>: (%d+):(%d+)'
}

local function parse_coverage(message_lines, tla_file)
  local action, line, column, module, distinct, total = string.match(message_lines[1], Pattern.Coverage)
  local tag = string.format('%s\t%s\tnorm %sG%s|\n', action, tla_file, line, column)
  return tag
end

M.parse_msg_start = function(str) return string.match(str, Pattern.MsgStart) end
M.parse_msg_end = function(str) return string.match(str, Pattern.MsgEnd) end

M.parse_msg = function(msg_lines, msg_type, tla_file)
  if msg_type == MessageType.Coverage then
    return parse_coverage(msg_lines, tla_file)
  end
end

return M
