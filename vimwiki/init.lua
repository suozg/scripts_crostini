-- =============================================================================
-- 0. СИСТЕМНІ НАЛАШТУВАННЯ ТА ШЛЯХИ
-- =============================================================================
vim.g.python3_host_prog = '/home/alex320388/venv/bin/python3'
vim.env.PATH = "/home/alex320388/venv/bin:" .. vim.env.PATH

-- Вимикаємо зайві провайдери для швидкого старту
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1

-- =============================================================================
-- 1. МЕНЕДЖЕР ПЛАГІНІВ (vim-plug)
-- =============================================================================
local plug_path = vim.fn.stdpath('data') .. '/site/autoload/plug.vim'
if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
    vim.fn.system({
        'curl', '-fLo', plug_path, '--create-dirs', 
        'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    })
end

vim.cmd([[
call plug#begin('~/.local/share/nvim/plugged')
    Plug 'xolox/vim-misc'
    Plug 'xolox/vim-session'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() }, 'on': 'Files' }
    Plug 'junegunn/fzf.vim', { 'on': ['Files', 'Rg', 'Buffers'] }
    Plug 'windwp/nvim-autopairs', { 'event': 'InsertEnter' }
    Plug 'tpope/vim-commentary'
    Plug 'lewis6991/gitsigns.nvim', { 'tag': 'v0.5' }
    Plug 'vimwiki/vimwiki'
    Plug 'plasticboy/vim-markdown'
    Plug 'dhruvasagar/vim-table-mode'
    Plug 'godlygeek/tabular'
    Plug 'lukas-reineke/indent-blankline.nvim', { 'tag': 'v2.20.8' }
call plug#end()
]])

-- =============================================================================
-- 2. ЗАГАЛЬНІ ОПЦІЇ (Options)
-- =============================================================================
local opt = vim.opt
opt.relativenumber = false
opt.number = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
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
-- Включаем сворачивание
opt.foldmethod = "indent"
-- Все folds раскрыты при открытии файла
opt.foldlevelstart = 99
-- Включаем возможность сворачивания
opt.foldenable = true

-- ============================
-- 3. Markdown && wiki
-- ============================
vim.g.vimwiki_list = {
  {
    path = os.getenv("HOME") .. '/awards/vimwiki/',  -- путь к папке wiki
    syntax = 'markdown',                             -- используем Markdown
    ext = '.md'                                      -- расширение файлов
  }
}
vim.g.vimwiki_auto_header = 1
vim.g.vimwiki_auto_chdir = 1
vim.g.vimwiki_use_calendar = 1
vim.api.nvim_set_keymap('n', '<leader>ww', ':VimwikiIndex<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ws', ':VimwikiSearch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap(
  'n',
  '<leader>wp',
  ':terminal glow %<CR>',
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap('n', '<leader>wd', ':VimwikiMakeDiaryNote<CR>', { noremap = true, silent = true })
-- Вирівнювання таблиць (Tabular)
vim.api.nvim_set_keymap('n', '<leader>ta', ':Tabularize /|<CR>', { noremap = true, silent = true })

vim.g.vim_markdown_folding_disabled = 1      -- вимикаємо згортання
vim.g.vim_markdown_conceal = 0              -- показуємо усі символи
vim.g.vim_markdown_new_list_item_indent = 2 -- відступи для списків


-- =============================================================================
-- 4. ТЕМА ТА ВІЗУАЛІЗАЦІЯ
-- =============================================================================
-- 4.1. Лінії відступів
vim.opt.list = false 
vim.g.indent_blankline_char = '│'
vim.g.indent_blankline_show_trailing_blankline_indent = false
vim.g.indent_blankline_filetype_exclude = { 'help', 'terminal', 'dashboard', 'fzf' }
vim.g.indent_blankline_enabled = true

-- 4.2. Налаштування кольорів орфографії
vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = 'Red', fg = 'Red' })
vim.api.nvim_set_hl(0, 'SpellCap', { undercurl = true, sp = 'Brown', fg = 'Brown' })

-- 4.3. Логіка теми
local theme_file = vim.fn.expand("~/.lightmode")
local gruvbox_exists = vim.fn.filereadable(vim.fn.expand("~/.config/nvim/colors/gruvbox.vim")) == 1

local function set_theme(mode)
    if gruvbox_exists then
        vim.g.gruvbox_italic = 1
        vim.g.gruvbox_bold = 1
        if mode == "dark" then
            vim.o.background = "dark"
            vim.g.gruvbox_contrast_dark = 'hard'
            vim.cmd("colorscheme gruvbox")
        else
            vim.o.background = "light"
            vim.g.gruvbox_contrast_light = 'soft'
            vim.cmd("colorscheme gruvbox")
            vim.api.nvim_set_hl(0, 'Normal', { bg = '#E3E2CF' })
            vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#E3E2CF' })
            vim.api.nvim_set_hl(0, 'LineNr', { bg = '#E3E2CF', fg = '#7c6f64' })
            vim.api.nvim_set_hl(0, 'SignColumn', { bg = '#E3E2CF' })
            vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = '#E3E2CF' }) 
        end
    else
        vim.o.background = "dark"
        vim.cmd("colorscheme desert")
    end
end

if vim.fn.filereadable(theme_file) == 1 then
    local mode = vim.fn.trim(vim.fn.readfile(theme_file)[1])
    set_theme(mode)
else
    set_theme("dark")
end

-- =============================================================================
-- 5. ГАРЯЧІ КЛАВІШІ 
-- =============================================================================
local function map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true }, opts or {}))
end

-- F-клавіші (Налаштування)
map('n', '<F8>', ':set number! relativenumber!<CR>')
map('n', '<F7>', ':set wrap! linebreak!<CR>')
map('n', '<F9>', ':setlocal spell!<CR>')
map('n', '<F6>', ':set list!<CR>')

-- Робота з текстом та буферами
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map('n', '<A-j>', ':m .+1<CR>==')
map('n', '<A-k>', ':m .-2<CR>==')
map('n', '<C-j>', ':bn<CR>')
map('n', '<C-k>', ':bp<CR>')
map('n', '<C-n>', ':tabnext<CR>')
map('n', '<C-p>', ':tabprevious<CR>')

-- Провідник та Пошук
map('n', '<leader>e', ':Lexplore<CR>')
map('n', '<leader>ff', ':Files<CR>')
map('n', '<leader>fg', ':Rg<CR>')
map('n', '<leader>fb', ':Buffers<CR>')
map('n', '<leader>fh', ':History<CR>')

map("n", "zR", "zR")  -- открыть все folds
map("n", "zM", "zM")  -- закрыть все folds
map("n", "za", "za")  -- переключить текущий fold
map("n", "zc", "zc")  -- закрыть текущий fold
map("n", "zo", "zo")  -- открыть текущий fold

-- map('n', 'gr', vim.lsp.buf.references)
-- map('n', 'gi', vim.lsp.buf.implementation)
-- map('n', '<leader>ca', vim.lsp.buf.code_action)
-- map('n', '<leader>ds', vim.diagnostic.open_float)

-- функция для открытия справки
-- Глобальная переменная для хранения номера буфера справки
_G.cheatsheet_buf = nil

-- Функция toggle
_G.toggle_cheatsheet = function()
    local path = vim.fn.expand("~/awards/help_vim.txt")
    local total_width = vim.o.columns
    local cheatsheet_width = math.floor(total_width / 3)

    -- Если буфер уже открыт, закрываем его
    if _G.cheatsheet_buf and vim.api.nvim_buf_is_valid(_G.cheatsheet_buf) then
        -- Найти окно, где открыт буфер
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == _G.cheatsheet_buf then
                vim.api.nvim_win_close(win, true)
                _G.cheatsheet_buf = nil
                return
            end
        end
    end

    -- Иначе — открыть cheatsheet
    vim.cmd("vsplit " .. path)
    vim.cmd("vertical resize " .. cheatsheet_width)

    local bufnr = vim.api.nvim_get_current_buf()
    _G.cheatsheet_buf = bufnr

    -- Настройки буфера
    vim.cmd("setlocal readonly")
    vim.cmd("setlocal wrap")
    vim.cmd("setlocal cursorline")
    vim.cmd("setlocal nomodifiable")
end

-- Горячая клавиша toggle <leader>1
vim.api.nvim_set_keymap(
    "n",
    "<leader>1",
    ":lua _G.toggle_cheatsheet()<CR>",
    { noremap = true, silent = true }
)


-- =============================================================================
-- 6 АВТОДОПОВНЕННЯ (Tab)
-- =============================================================================
-- Розумний Tab
function _G.smart_tab()
    local col = vim.fn.col('.') - 1
    local line = vim.fn.getline('.')
    if col == 0 or line:sub(col, col):match('%s') then
        return vim.api.nvim_replace_termcodes('<Tab>', true, true, true)
    end
    -- Якщо включена перевірка орфографії, Tab пропонує виправлення
    if vim.wo.spell then
        return vim.api.nvim_replace_termcodes('<C-x><C-s>', true, true, true)
    end
    -- В іншому випадку — стандартне доповнення по тексту
    return vim.api.nvim_replace_termcodes('<C-n>', true, true, true)
end
vim.keymap.set('i', '<Tab>', 'v:lua.smart_tab()', { expr = true, noremap = true })
vim.keymap.set('i', '<S-Tab>', '<C-p>', { noremap = true })

-- автозакриття дужок
local ok, autopairs = pcall(require, "nvim-autopairs")
if ok then
    autopairs.setup({
        check_ts = false,  
        enable_check_bracket_line = false,
        fast_wrap = {
            map = '<M-e>',
            chars = { '{', '[', '(', '"', "'" },
            end_key = '$',
        },
    })
end

-- =============================================================================
-- 7. АВТОМАТИКА ТА СИСТЕМНІ ФУНКЦІЇ
-- =============================================================================
-- 7.1. Курсор та Розкладка
local OPTIONS = "lv3:ralt_switch"
local saved_layout = "us"

local function get_layout()
    local handle = io.popen("setxkbmap -query | awk '/layout/{print $2}'")
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+", "")
end

local function set_layout(layout)
    vim.fn.system("setxkbmap -layout " .. layout .. " -option " .. OPTIONS)
    vim.fn.system("pkill -RTMIN+1 dwmblocks")
end

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- 7.2. Орфографія для Markdown
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "html", "text" },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.spelllang = { "uk", "en_us" }
        vim.opt.spelloptions = "camel"
    end,
})

-- Команда форматування спеціально для Markdown через системний pandoc або інше
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(args)
        vim.api.nvim_buf_create_user_command(args.buf, 'LspFormat', function()
            -- Якщо немає LSP, можна просто викликати зовнішній форматувальник
            -- Наприклад, за допомогою pandoc:
            vim.cmd("%!pandoc -f markdown -t markdown")
            print("Markdown formatted via Pandoc")
        end, { desc = 'Format Markdown buffer' })
    end,
})

-- 7.3 підсвітка yank
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- 7.4  Автоперехід у insert після терміналу
vim.api.nvim_create_autocmd("TermOpen", {
    callback = function()
        vim.cmd("startinsert")
    end
})

-- 7.5 
-- vim.diagnostic.config({
--     virtual_text = false,
--     signs = true,
--     underline = true,
--     update_in_insert = false,
-- })

-- =============================================================================
-- 8. СТАТУСБАР
-- =============================================================================
local display_spell = "OFF"
local function update_status_values()
    if vim.opt.spell:get() then
        local lang = vim.opt.spelllang:get()[1]
        display_spell = (lang == "uk" and "UA" or (lang == "en_us" and "EN" or lang:upper()))
    else
        display_spell = "OFF"
    end
end

vim.api.nvim_create_autocmd("InsertEnter", {
    callback = function()
        if saved_layout then set_layout(saved_layout) end
        update_status_values()
    end
})

vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        saved_layout = get_layout()
        if saved_layout ~= "us" then set_layout("us") end
        update_status_values()
    end
})

vim.api.nvim_create_autocmd({"OptionSet", "BufEnter"}, {
    callback = function()
        update_status_values()
        vim.cmd('redrawstatus')
    end
})

function _G.get_spell_lang() return display_spell end

function _G.get_buffer_status()
    local listed_bufs = vim.fn.getbufinfo({buflisted = 1})
    local current_buf = vim.fn.bufnr('%')
    local current_index = 0
    for i, buf in ipairs(listed_bufs) do
        if buf.bufnr == current_buf then current_index = i break end
    end
    return (#listed_bufs > 1) and string.format(" [B:%d/%d] ", current_index, #listed_bufs) or ""
end

function _G.get_tab_status()
    local total = vim.fn.tabpagenr('$')
    return (total > 1) and string.format(" [T:%d/%d] ", vim.fn.tabpagenr(), total) or ""
end

function _G.statusline()
    local function flag(enabled, label, key)
        return string.format(
            "[%s:%s]",
            label,
            enabled and key or "off"
        )
    end

    local list   = flag(vim.o.list,   "LST", "F6")
    local wrap   = flag(vim.o.wrap,   "WRP", "F7")
    local number = flag(vim.o.number, "NUM", "F8")
    local spell  = string.format("[SPELL:%s:F9]", _G.get_spell_lang())

    return table.concat({
        " %f %m %y ",
        _G.get_buffer_status(),
        _G.get_tab_status(),
        "%=",
        list, " ",
        wrap, " ",
        number, " ",
        spell, " ",
        " %l/%L:%c "
    })
end

vim.opt.statusline = "%!v:lua.statusline()"

-- =============================================================================
-- 9. ЕКСПОРТ (PDF/HTML) ТА FZF СПЕЛЛІНГ
-- =============================================================================
-- Експорт PDF / HTML
local is_executable = function(cmd) return vim.fn.executable(cmd) == 1 end
local last_exported_hash = {}
local pdf_templates = {}
local cached_templates = {}

local function get_hash(content) return vim.fn.sha256(content) end

local function is_zathura_open(pdf_file)
    local handle = io.popen("pgrep -af zathura")
    if not handle then return false end
    local result = handle:read("*all")
    handle:close()
    return result:find(pdf_file, 1, true) ~= nil
end

-- Основне ядро: Генерація HTML
local function core_generate_html(template_path, callback)
    local input = vim.fn.expand('%:p')
    local output_html = vim.fn.expand('%:p:r') .. '.html'
    local ext = vim.fn.expand('%:e')
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    if input == '' then print('Помилка: Файл не збережено.'); return end

    if ext == 'md' then
        if not is_executable('pandoc') then print('Помилка: pandoc не встановлено.'); return end
        local lua_filter = vim.fn.expand('~/.config/nvim/list-table.lua')
        -- Додамо перевірку самого шаблону для Pandoc
        if vim.fn.filereadable(template_path) == 0 then
            print('Помилка: Шаблон не знайдено: ' .. template_path)
            return
        end
        vim.fn.jobstart({ 'pandoc', input, '--lua-filter=' .. lua_filter, '--template=' .. template_path, '-o', output_html }, {
            on_exit = function(_, code) if code == 0 then callback(output_html) else print('Помилка Pandoc') end end
        })
    else
        -- БЕЗПЕЧНЕ ЧИТАННЯ ШАБЛОНУ ТУТ:
        local tmpl = cached_templates[template_path]
        if not tmpl then
            local f = io.open(template_path, 'r')
            if not f then 
                print('Помилка: Не вдалося відкрити шаблон за шляхом: ' .. template_path)
                return 
            end
            tmpl = f:read('*all')
            f:close()
            cached_templates[template_path] = tmpl
        end

        local escaped = content:gsub('<', '&lt;'):gsub('>', '&gt;')
        local final_html = tmpl:gsub('%$body%$', '<pre>' .. escaped .. '</pre>')
        
        local f_out = io.open(output_html, 'w')
        if f_out then 
            f_out:write(final_html)
            f_out:close()
            callback(output_html) 
        else 
            print('Помилка запису HTML') 
        end
    end
end

-- Функція експорту (універсальна)
local function run_export(type, template_path)
    local base = vim.fn.expand('%:p:r')
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    core_generate_html(template_path, function(html_file)
        if type == 'pdf' then
            local pdf_file = base .. '.pdf'
            pdf_templates[pdf_file] = template_path
            vim.fn.jobstart({ 'weasyprint', '-s', vim.fn.expand('~/.config/nvim/pdf.css'), html_file, pdf_file }, {
                on_exit = function(_, code)
                    if code == 0 then
                        -- os.remove(html_file)
                        last_exported_hash[vim.api.nvim_get_current_buf()] = get_hash(content)
                        if not is_zathura_open(pdf_file) then 
                            vim.fn.jobstart({ 'zathura', '--fork', pdf_file }, { detach = true }) 
                        end
                        print('PDF оновлено')
                    end
                end
            })
        elseif type == 'html' then
            vim.fn.jobstart({ 'xdg-open', html_file }, { detach = true })
            print('HTML відкрито в браузері')
        end
    end)
end

-- Універсальний вибір шаблону
local function select_template(callback)
    local dir = vim.fn.expand("~/.config/nvim/templates/")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
    local templates = vim.fn.glob(dir .. "*.html", false, true)
    if #templates == 0 then 
        print("Каталог шаблонів порожній: " .. dir)
        return 
    end
    vim.ui.select(templates, { prompt = 'Виберіть шаблон:', format_item = function(item) return vim.fn.fnamemodify(item, ":t") end }, callback)
end

-- Клавіші
local default_tmpl = vim.fn.expand("~/.config/nvim/templates/standard.html")

vim.keymap.set("n", "<leader>b",  function() run_export('pdf', default_tmpl) end)
vim.keymap.set("n", "<leader>bt", function() select_template(function(choice) if choice then run_export('pdf', choice) end end) end)
vim.keymap.set("n", "<leader>h",  function() run_export('html', default_tmpl) end)
vim.keymap.set("n", "<leader>ht", function() select_template(function(choice) if choice then run_export('html', choice) end end) end)

-- Автокоманда
vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('PdfAutoExport', { clear = true }),
    callback = function()
        local pdf_file = vim.fn.expand('%:p:r') .. '.pdf'
        if is_zathura_open(pdf_file) then
            local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
            if last_exported_hash[vim.api.nvim_get_current_buf()] ~= get_hash(content) then
                run_export('pdf', pdf_templates[pdf_file] or default_tmpl)
            end
        end
    end
})

-- FZF Spell Suggestion
vim.keymap.set('n', '<leader>z', function()
    local word = vim.fn.expand('<cword>')
    local suggestions = vim.fn.spellsuggest(word)
    vim.fn['fzf#run'](vim.fn['fzf#wrap']({
        source = suggestions,
        sink = function(selected) vim.cmd('normal! "_ciw' .. selected) end,
        options = '--prompt="Spell> " --preview-window=hidden',
    }))
end)

-- створення таблиці (справа текст - зліва порожня ячійка)
vim.api.nvim_create_user_command('MakeTable', function()
    -- 1. Удаляем все пустые строки
    vim.cmd([[g/^\s*$/d]])
    -- 2. Додаємо символи '|' на початку та в кінці кожного рядка
    vim.cmd([[%s/^/| /]])
    vim.cmd([[%s/$/ | |/]])
    -- 3. Вставляємо шапку на самий початок (рядки 1 та 2)
    vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "| Дані | Коментар |",
        "| --- | --- |"
    })
    -- 4. Опціонально: вирівнюємо все для краси (якщо встановлено util-linux)
    vim.cmd([[ %!column -t -s '|' -o '|' ]])
    
    print("Таблиця готова! Збережіть файл перед створенням html")
end, {})
vim.keymap.set('n', '<leader>t', ':MakeTable<CR>', { desc = 'Перетворити список на Markdown таблицю' })
