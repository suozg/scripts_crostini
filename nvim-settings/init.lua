-- ~/.config/nvim
-- │
-- ├── init.lua
-- │
-- └── lua
--     ├── config
--     │   ├── autocmds.lua
--     │   ├── keymaps.lua
--     │   ├── lazy.lua
--     │   ├── options.lua
--     │   ├── statusline.lua
--     │   └── theme.lua
--     │
--     └── plugins
--         ├── editor.lua
--         ├── lsp.lua
--         ├── orgmode.lua
--         ├── treesitter.lua
--         └── ui.lua

vim.g.mapleader = " "

require("config.lazy")
require("config.options")
require("config.theme")
require("config.statusline")
require("config.autocmds")
require("config.keymaps")




