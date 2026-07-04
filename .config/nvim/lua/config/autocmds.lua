-- ================================================================================================
-- TITLE : auto-commands
-- ================================================================================================

-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
  group = last_cursor_group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    local ft = vim.bo.filetype
    local contains = vim.list_contains or vim.tbl_contains
    if not contains({ "gitcommit", "gitrebase" }, ft)
        and mark[1] > 0
        and mark[1] <= lcount
    then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Highlight the yanked text for 200ms
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ESLint: fixAll mentéskor JS/TS fájloknál
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("EslintFixAll", { clear = true }),
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "eslint" })
    if #clients > 0 then
      vim.cmd("EslintFixAll")
    end
  end,
})
