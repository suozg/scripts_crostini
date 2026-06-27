-- =============================================================================
-- 0. СИСТЕМНІ НАЛАШТУВАННЯ ТА ШЛЯХИ
-- =============================================================================
vim.g.python3_host_prog = '/home/alex320388/venv/bin/python3'
vim.env.PATH = "/home/alex320388/venv/bin:" .. vim.env.PATH
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/site"))

-- Вимикаємо непотрібні провайдери для прискорення завантаження
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.mapleader = " "

-- =============================================================================
-- 1. ПЛАГІНИ (Vim-Plug)
-- =============================================================================
local plug_path = vim.fn.stdpath('data') .. '/site/autoload/plug.vim'
if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
    vim.fn.system({
        'curl','-fLo',plug_path,'--create-dirs',
        'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    })
end

vim.cmd([[
call plug#begin('~/.local/share/nvim/plugged')
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'windwp/nvim-autopairs'
    Plug 'tpope/vim-commentary'
    Plug 'lewis6991/gitsigns.nvim', { 'tag': 'v0.5' }
    Plug 'nvim-orgmode/orgmode'
    Plug 'dhruvasagar/vim-table-mode'
    Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'    
    Plug 'neovim/nvim-lspconfig'
    Plug 'godlygeek/tabular'
    Plug 'lukas-reineke/indent-blankline.nvim', { 'tag': 'v2.20.8' }
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-path'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'saadparwaiz1/cmp_luasnip'
    Plug 'nvim-neo-tree/neo-tree.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'MunifTanjim/nui.nvim'
call plug#end()
]])

-- =============================================================================
-- 2. OPTIONS (Налаштування)
-- =============================================================================
local opt = vim.opt
opt.number = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.mouse = "a"
opt.completeopt = "menuone,noselect"
opt.list = false
opt.listchars = { tab = '→ ', trail = '·', eol = '↲', space = '·' }
opt.foldmethod = "indent"
opt.foldlevelstart = 99
opt.foldenable = true
opt.updatetime = 300
opt.conceallevel = 2
opt.concealcursor = 'nc'

-- =============================================================================
-- 3. ПЛАГІНИ: НАЛАШТУВАННЯ (Lua)
-- =============================================================================
-- Orgmode
local ok_org, orgmode = pcall(require, 'orgmode')
if ok_org then
  orgmode.setup({
    org_agenda_files = {'~/awards/org/*.org'},
    org_default_notes_file = '~/awards/org/diary.org',

    org_todo_keywords = {
      'TODO',
      'NEXT',
      'WAIT',
      '|',
      'DONE',
      'CANCELLED'
    },

    org_capture_templates = {
      t = {
        description = 'Завдання',
        template = '* TODO %?\nSCHEDULED: %T'
      }
    }
  })
end

-- Autopairs
local ok_ap, autopairs = pcall(require, "nvim-autopairs")
if ok_ap then autopairs.setup({}) end

-- Indent Blankline (v2 config)
vim.g.indent_blankline_char = '│'
vim.g.indent_blankline_show_trailing_blankline_indent = false
vim.g.indent_blankline_filetype_exclude = { 'help', 'terminal', 'dashboard', 'fzf' }


-- =============================================================================
-- БЛОК LSP & CMP 
-- =============================================================================
require("mason").setup()

local servers = { "lua_ls", "pyright", "ts_ls", "bashls" }

require("mason-lspconfig").setup({
    ensure_installed = servers
})

-- Налаштування nvim-cmp
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer',
      option = {
        keyword_pattern = [[[^%s]\+]]
      }
    },
    { name = 'path' },
  }
})

-- Отримуємо capabilities від cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Сучасна ініціалізація серверів згідно з вимогами lspconfig-nvim-0.11
for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        capabilities = capabilities,
    })
    vim.lsp.enable(server)
end


-- =============================================================================
-- 4. ТЕМА ТА ВІЗУАЛІЗАЦІЯ
-- =============================================================================
vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = 'Red', fg = 'Red' })
vim.api.nvim_set_hl(0, 'SpellCap', { undercurl = true, sp = 'Brown', fg = 'Brown' })

local function set_theme(mode)
    local gruvbox_exists = vim.fn.filereadable(vim.fn.expand("~/.config/nvim/colors/gruvbox.vim")) == 1
    if gruvbox_exists then
        vim.g.gruvbox_italic = 1
        vim.g.gruvbox_bold = 1
        if mode == "dark" then
            vim.o.background = "dark"
            vim.g.gruvbox_contrast_dark = 'hard'
        else
            vim.o.background = "light"
            vim.g.gruvbox_contrast_light = 'soft'
            vim.cmd("colorscheme gruvbox")
            -- Кастомні кольори для світлої теми
            local hl = vim.api.nvim_set_hl
            hl(0, 'Normal', { bg = '#E3E2CF' })
            hl(0, 'NormalFloat', { bg = '#E3E2CF' })
            hl(0, 'LineNr', { bg = '#E3E2CF', fg = '#7c6f64' })
            hl(0, 'SignColumn', { bg = '#E3E2CF' })
            hl(0, 'EndOfBuffer', { bg = '#E3E2CF' }) 
            return
        end
        vim.cmd("colorscheme gruvbox")
    else
        vim.o.background = "dark"
        vim.cmd("colorscheme desert")
    end
end

local theme_file = vim.fn.expand("~/.lightmode")
if vim.fn.filereadable(theme_file) == 1 then
    local mode = vim.fn.trim(vim.fn.readfile(theme_file)[1])
    set_theme(mode)
else
    set_theme("dark")
end

-- смена цвета статусбар при изменении режима
local function set_statusline_mode_colors()
    vim.api.nvim_set_hl(0, "StatusLineNormal", { bg = "#3c3836", fg = "#ebdbb2" })
    vim.api.nvim_set_hl(0, "StatusLineInsert", { bg = "#2e7d32", fg = "#ffffff" }) -- зелёный
end

set_statusline_mode_colors()


-- =============================================================================
-- 5. KEYMAPS
-- =============================================================================
local function map(m, l, r) vim.keymap.set(m, l, r, {silent=true}) end
map('n', '<F6>', ':set list!<CR>')  
map('n','<F8>',':set number!<CR>')
map('n','<F7>',':set wrap!<CR>')
map('n','<F9>',':setlocal spell!<CR>')
map('n','<C-j>',':bn<CR>')
map('n','<C-k>',':bp<CR>')

-- FZF
map('n','<leader>ff',':Files<CR>')
map('n','<leader>fg',':Rg<CR>')
map('n','<leader>fb',':Buffers<CR>')

-- ORG
map('n','<leader>oa',':OrgAgenda<CR>')
map('n','<leader>oc',':OrgCapture<CR>')
map('n','<leader>ot',':OrgTodoToggle<CR>')

-- запуск файлового менеджера
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })


-- =============================================================================
-- 6. AUTOCMDS
-- =============================================================================
local augroup = vim.api.nvim_create_augroup("CustomConfig", {clear = true})

vim.api.nvim_create_autocmd("FileType",{
  group = augroup,
  pattern = {"org","text"},
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = {"uk","en_us"}
  end
})

vim.api.nvim_create_autocmd("TextYankPost",{
  group = augroup,
  callback = function() vim.highlight.on_yank({timeout=200}) end
})

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.org",
    callback = function()
        os.execute("pkill -RTMIN+10 dwmblocks")
    end,
})

-- автокоманди для изменения цвета статусбар
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    callback = function()
        vim.api.nvim_set_hl(0, "StatusLine", { link = "StatusLineInsert" })
    end
})

vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    callback = function()
        vim.api.nvim_set_hl(0, "StatusLine", { link = "StatusLineNormal" })
    end
})


-- =============================================================================
-- 7.1. РОБОТА З РОЗКЛАДКОЮ ТА СИГНАЛ ДЛЯ DWM
-- =============================================================================
local OPTIONS = "lv3:ralt_switch"
local saved_layout = "us"

local function get_layout()
    -- Використовуємо pcall, щоб уникнути переривань при помилках читання
    local handle = io.popen("setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}'")
    if not handle then return "us" end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+", ""):split(',')[1] or "us" 
end

local function set_layout(layout)
    vim.fn.system(string.format("setxkbmap -layout %s -option %s 2>/dev/null", layout, OPTIONS))
    vim.fn.system("pkill -RTMIN+1 dwmblocks 2>/dev/null")
end

function string:split(sep)
    local res = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) res[#res+1] = c end)
    return res
end

vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup,
    callback = function()
        if saved_layout and saved_layout ~= "" then 
            set_layout(saved_layout) 
        end
    end
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = function()
        local current = get_layout()
        if current ~= "" then saved_layout = current end
        if saved_layout ~= "us" then 
            set_layout("us") 
        end
    end
})

-- =============================================================================
-- 8. STATUSLINE
-- =============================================================================
function _G.statusline()
    local function flag(opt_name, label, key)
        local enabled = vim.opt[opt_name]:get()
        return string.format("[%s:%s]", label, enabled and key or "off")
    end

    local spell_state = "OFF"
    if vim.opt.spell:get() then
        local lang = vim.opt.spelllang:get()[1]
        spell_state = (lang == "uk" and "UA" or (lang == "en_us" and "EN" or lang:upper()))
    end

    local bufs = vim.fn.getbufinfo({buflisted = 1})
    local b_idx = 0
    for i, b in ipairs(bufs) do if b.bufnr == vim.fn.bufnr('%') then b_idx = i break end end
    local b_stat = (#bufs > 1) and string.format(" [B:%d/%d] ", b_idx, #bufs) or ""

    return table.concat({
        " %f %m %y ", b_stat, "%=",
        flag("list", "LST", "F6"), " ",
        flag("wrap", "WRP", "F7"), " ",
        flag("number", "NUM", "F8"), " ",
        string.format("[SPELL:%s:F9]", spell_state),
        " %l/%L:%c "
    })
end

vim.opt.statusline = "%!v:lua.statusline()"

-- =============================================================================
-- 9. РОБОТА З ТАБЛИЦЯМИ
-- =============================================================================
-- Команда створює таблицю з виділеного тексту або рядка
vim.api.nvim_create_user_command('MakeTable', function(opts)
    local r1, r2 = opts.line1, opts.line2
    vim.cmd(string.format([[%d,%dg/^\s*$/d]], r1, r2))
    vim.cmd(string.format([[%d,%ds/^/| /]], r1, r2))
    vim.cmd(string.format([[%d,%ds/$/ | |/]], r1, r2))
    vim.fn.append(r1 - 1, {"| Дані | Коментар |", "| --- | --- |"})
    vim.cmd(string.format([[%d,%d!column -t -s '|' -o '|']], r1, r2 + 2))
end, {range = true})

map('n', '<leader>t', ':MakeTable<CR>')
map('v', '<leader>t', ':MakeTable<CR>')

