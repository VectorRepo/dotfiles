-- ================================================================================================
-- TITLE: NeoVim keymaps
-- ================================================================================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Navigáció / görgetés
map("n", "n",      "nzzzv",    { desc = "Next search result (centered)" })
map("n", "N",      "Nzzzv",    { desc = "Previous search result (centered)" })
map("n", "<C-d>",  "<C-d>zz",  { desc = "Half page down (centered)" })
map("n", "<C-u>",  "<C-u>zz",  { desc = "Half page up (centered)" })

-- Spell
map("n", "<leader>z", "]sz=", { desc = "Next Spell Suggestion" })

-- Buffer
map("n", "<leader>bn", "<Cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Ablaknavigáció
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Split
map("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", "<Cmd>split<CR>",  { desc = "Split window horizontally" })

-- Ablakméret
map("n", "<C-Up>",    "<Cmd>resize +2<CR>",          { desc = "Increase window height" })
map("n", "<C-Down>",  "<Cmd>resize -2<CR>",           { desc = "Decrease window height" })
map("n", "<C-Left>",  "<Cmd>vertical resize -2<CR>",  { desc = "Decrease window width" })
map("n", "<C-Right>", "<Cmd>vertical resize +2<CR>",  { desc = "Increase window width" })

-- Indent megtartja a kijelölést
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Sorok összefűzése kurzorpozíció megtartásával
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Config gyorsbillentyű
map("n", "<leader>rc", "<Cmd>e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

-- Alap fájlműveletek
map("n", "<leader>w", "<cmd>w<CR>",    opts)  -- Mentés
map("n", "<leader>q", "<cmd>q<CR>",    opts)  -- Kilépés
map("n", "<leader>n", "<cmd>enew<CR>", opts)  -- Új fájl

-- Oil.nvim – a keymapok az oil.lua keys{} táblájában vannak (lazy-load miatt)
-- itt NEM ismételjük meg

-- fzf-lua – a keymapok az fzf-lua.lua keys{} táblájában vannak (lazy-load miatt)
-- itt NEM ismételjük meg

-- LSP keymapok – az nvim-lsp.lua LspAttach autocmd-jében vannak (buffer-specifikus)
-- itt NEM ismételjük meg

-- mini.move – Alt+hjkl
local function mm_line(dir)
  return function()
    if MiniMove then MiniMove.move_line(dir) end
  end
end

local function mm_sel(dir)
  return function()
    if MiniMove then MiniMove.move_selection(dir) end
  end
end

map("n", "<M-h>", mm_line("left"),  { desc = "Move line left",       silent = true })
map("n", "<M-l>", mm_line("right"), { desc = "Move line right",      silent = true })
map("n", "<M-j>", mm_line("down"),  { desc = "Move line down",       silent = true })
map("n", "<M-k>", mm_line("up"),    { desc = "Move line up",         silent = true })

map("v", "<M-h>", mm_sel("left"),   { desc = "Move selection left",  silent = true })
map("v", "<M-l>", mm_sel("right"),  { desc = "Move selection right", silent = true })
map("v", "<M-j>", mm_sel("down"),   { desc = "Move selection down",  silent = true })
map("v", "<M-k>", mm_sel("up"),     { desc = "Move selection up",    silent = true })
