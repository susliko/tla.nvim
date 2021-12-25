local curl = require('plenary.curl')
local Path = require('plenary.path')

local M = {}

-- Downloads latest version of tla2tools.jar if output_file not exists
M.install_tla2tools = function(output_file)
  output_file = Path:new(Path:new(output_file):expand())
  if output_file:exists() then return end
  if not output_file:parent():exists() then
     output_file:parent():mkdir()
  end
  local release_url = 'https://api.github.com/repos/tlaplus/tlaplus/releases/latest'
  local release_page = vim.fn.json_decode(curl.get(release_url).body)
  for _, asset in pairs(release_page.assets) do
    if asset['name'] == 'tla2tools.jar' then
      if not output_file:parent():exists() then
         output_file:parent():mkdir()
      end
      local download_url = asset['browser_download_url']
      curl.get(download_url, {output = output_file.filename})
      print('Installed tla2tools ' .. release_page.tag_name .. ', enjoy your specs!')
    end
  end
end

return M
