-- ================================================================================================
-- TITLE : NeoVim options (ÚJ ALAP + SAJÁT felülírások)
-- ================================================================================================

-- Basic Settings (ÚJ ALAP)
vim.opt.number = true -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
-- vim.opt.cursorline = true -- [SAJÁT VÁLTOZTATÁS] false-ra állítva (saját: false)
vim.opt.cursorline = false
vim.opt.scrolloff = 10 -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
-- vim.opt.wrap = true -- [SAJÁT VÁLTOZTATÁS] false-ra állítva (saját: false)
vim.opt.wrap = false
vim.opt.cmdheight = 1 -- Command line height
-- vim.opt.spell = true -- [SAJÁT VÁLTOZTATÁS] false-ra állítva (saját: nincs spell)
vim.opt.spell = false
-- vim.opt.spelllang = "en_us" -- [ELTÁVOLÍTVA] magyar felhasználó, kellhet később

-- Tabbing / Indentation (mindkettő azonos)
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Search Settings
-- vim.opt.smartcase = false -- [SAJÁT VÁLTOZTATÁS] true-ra (saját: true)
vim.opt.smartcase = true
-- vim.opt.hlsearch = true -- [SAJÁT VÁLTOZTATÁS] marad true (saját is true)
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true

-- Visual Settings
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.showmatch = true
vim.opt.matchtime = 2
-- vim.opt.completeopt = "menuone,noinsert,noselect" -- [SAJÁT VÁLTOZTATÁS] "menuone,noselect"-re 
vim.opt.completeopt = "menuone,noselect"
vim.opt.showmode = false
vim.opt.pumheight = 10
vim.opt.pumblend = 0   -- 0 = teljesen átlátszó popup háttér (terminál háttér látszik)
vim.opt.winblend = 0
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.lazyredraw = false  -- [SAJÁT VÁLTOZTATÁS] true-ra (saját: true)
vim.opt.lazyredraw = true
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000
vim.opt.synmaxcol = 300

-- File Handling
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.updatetime = 250
-- vim.opt.timeoutlen = 2000 -- [SAJÁT VÁLTOZTATÁS] 300-ra (saját: 300)
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false
vim.opt.diffopt:append("vertical")
vim.opt.diffopt:append("algorithm:patience")
vim.opt.diffopt:append("linematch:60")

-- Undo directory (ÚJ)
local undodir = "~/.local/share/nvim/undodir"
vim.opt.undodir = vim.fn.expand(undodir)
if vim.fn.isdirectory(vim.fn.expand(undodir)) == 0 then
	vim.fn.mkdir(vim.fn.expand(undodir), "p")
end

-- Behavior Settings
vim.opt.backspace = "indent,eol,start"
vim.opt.autochdir = false
vim.opt.path:append("**")
vim.opt.selection = "inclusive"
vim.opt.mouse = "a"
vim.opt.clipboard:append("unnamedplus")
vim.opt.modifiable = true
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignorecase = true
vim.opt.fileencoding = "utf-8"  -- [SAJÁT HOZZÁADVA]

-- Folding
vim.opt.foldlevel = 99
vim.opt.foldmethod = "indent"

-- Split Behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

-- SAJÁT SPECIFIKUS HOZZÁADÁSOK
vim.opt.showcmd = true         -- Saját
vim.opt.fillchars = { eob = " " }  -- Saját
vim.opt.background = "light"   -- Saját
vim.opt.smarttab = true        -- Saját
vim.opt.breakindent = true     -- Saját
vim.opt.formatoptions:append("r")  -- Saját
vim.opt.maxmapdepth = 2000     -- Saját
vim.opt.splitkeep = "cursor"   -- Saját
vim.opt.inccommand = "split"   -- Saját
