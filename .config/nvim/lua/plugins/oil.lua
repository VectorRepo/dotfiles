return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- Keymapok ITT vannak definiálva (lazy-load triggerként is működnek)
  -- keymaps.lua-ban NINCS Oil keymap → nincs duplikáció
  keys = {
    { "-",          "<cmd>Oil<cr>", desc = "Oil" },
    { "<leader>e",  "<cmd>Oil<cr>", desc = "Oil" },
  },
  config = function()
    require("oil").setup({
      columns = {
        "icon",
        "permissions",  -- rwxr-xr-x
        "size",         -- 1.2K
        "mtime",        -- 01/27 15:10
      },
      win_options = {
        winblend  = 0,
        wrap      = false,
        signcolumn = "no",
      },
      view_options = {
        show_hidden = true,
      },
      delete_to_trash = true,
    })

    -- q → bezárás (buffer-specifikus, noremap)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil",
      callback = function()
        vim.keymap.set("n", "q", "<cmd>bdelete<cr>", {
          buffer  = true,
          silent  = true,
          noremap = true,
          desc    = "Oil close",
        })
      end,
    })
  end,
}
