-- nvim-treesitter main branch (új API, Neovim 0.12 kompatibilis)
-- A master branch range() nil hibát dob 0.12-ben markdown és egyéb fájloknál.
-- A main branch-en a nvim-treesitter.configs modul nem létezik,
-- highlight/indent/fold engedélyezése FileType autocmd-del történik.
return {
  "nvim-treesitter/nvim-treesitter",
  version = false,
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  lazy = vim.fn.argc(-1) == 0,
  main = "nvim-treesitter",
  opts = {
    ensure_installed = {
      "bash", "c", "cpp", "css", "dockerfile", "go", "html",
      "javascript", "json", "lua", "markdown", "markdown_inline",
      "python", "query", "regex", "rust", "svelte", "typescript",
      "vim", "vimdoc", "vue", "yaml",
    },
    auto_install = true,
    sync_install = false,
  },
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("NvimTreesitterInit", { clear = true }),
      callback = function()
        -- Highlight
        pcall(vim.treesitter.start)
        -- Fold (csak ha a parser elérhető)
        local ok = pcall(function()
          local p = vim.treesitter.get_parser(0)
          if p then p:parse() end
        end)
        if ok then
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
        end
        -- indentexpr szándékosan NINCS beállítva:
        -- a treesitter indent az 'o' paranccsal rosszul pozicionál,
        -- a Neovim beépített smartindent megbízhatóbb
      end,
    })
  end,
}
