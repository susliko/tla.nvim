local curl = require('plenary.curl')
local utils = require('tla.utils')
local Path = require('plenary.path')

local M = {}

-- Downloads latest version of tla2tools.jar,
-- rewrites existing jar in tla_nvim_cache_dir
M.install_tla2tools = function()
  local release_url = 'https://api.github.com/repos/tlaplus/tlaplus/releases/latest'
  local release_page = vim.fn.json_decode(curl.get(release_url).body)
  for _, asset in pairs(release_page.assets) do
    if asset['name'] == 'tla2tools.jar' then
      if not utils.tla_nvim_cache_dir:exists() then
         utils.tla_nvim_cache_dir:mkdir()
      end
      local download_url = asset['browser_download_url']
      local output_filename = Path:new(utils.tla_nvim_cache_dir, 'tla2tools.jar').filename
      curl.get(download_url, {output = output_filename})
      print('Installed tla2tools ' .. release_page.tag_name .. ', enjoy your specs!')
    end
  end
end

return M
