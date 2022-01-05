-- force lua to import the modules again
package.loaded["dev"] = nil
package.loaded["tla"] = nil
package.loaded["tla.check"] = nil
package.loaded["tla.config"] = nil
package.loaded["tla.install"] = nil
package.loaded["tla.parser"] = nil
package.loaded["tla.utils"] = nil
print("loadeded tla")
require("tla").setup()

-- [ , + r ] keymap to reload the lua file
-- NOTE: someone need to source this file to apply these configurations. So, the
-- very first time you open the project, you have to source this file using
-- ":luafile dev/init.lua". From that point onward, you can hit the keybind to
-- reload
vim.api.nvim_set_keymap("n", ",r", "<cmd>luafile dev/init.lua<cr>", {})

-- [ , + c ] keymap to run check function
vim.api.nvim_set_keymap("n", ",c", '<cmd>lua require("tla").check()<cr>', {})
vim.api.nvim_set_keymap("n", ",tr", '<cmd>lua require("tla").translate()<cr>', {})
vim.api.nvim_set_keymap("n", ",tt", "<Plug>PlenaryTestFile", {})
