local M = {}

M.concat_arrays = function(a, b)
  a = vim.deepcopy(a)
  for i=1,#b do
      a[#a+1] = b[i]
  end
  return a
end

M.get_current_file_path = function()
  return vim.api.nvim_buf_get_name(0):gsub('^%s+', ''):gsub('%s+$', '')
end

M.check_filetype_is_tla = function(filepath)
  local file_type = require'plenary.filetype'.detect(filepath)
  if file_type ~= 'tla' then
    error('Can run only on .tla files')
  end
end

M.get_or_create_output_buf = function(filepath)
  local buf_name = filepath .. ' '
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if buf_name == vim.api.nvim_buf_get_name(buf) then
      vim.bo[buf].filetype = 'help'
      return buf
    end
  end

  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(output_buf, buf_name)
  vim.bo[output_buf].filetype = 'help'

  return output_buf
end

M.focus_output_win = function(output_buf)
  local output_wins = vim.fn.win_findbuf(output_buf)
  if #output_wins == 0 then
    vim.api.nvim_command('vsp')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, output_buf)
  else
    vim.fn.win_gotoid(output_wins[1])
  end
end

M.append_to_buf = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

M.clear_buf = function(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

M.print_command_to_buf = function(output_buf, command, args)
  local args_str = table.concat(args, ' ')
  M.append_to_buf(output_buf, { 'Executing command:', command .. ' ' ..  args_str, '' })
end

return M
