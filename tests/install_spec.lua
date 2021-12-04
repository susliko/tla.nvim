local install = require('tla.install')
local utils = require('tla.utils')
local Path = require('plenary.path')
local eq = assert.are.same

describe('install scripts should', function ()
  it('install tla2tools', function ()
    install.install_tla2tools()
    local expected_path = Path:new(utils.tla_nvim_cache_dir, 'tla2tools.jar')
    eq(true, expected_path:exists())
  end)
end)
