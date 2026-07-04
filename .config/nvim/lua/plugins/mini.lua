return {
  "echasnovski/mini.nvim",
  version = false,
  event = "VeryLazy",
  config = function()
    -- Kommentelés: gc / gcc
    require("mini.comment").setup()

    -- Mozgatás: alapból <M-hjkl> (Alt+hjkl)
    require("mini.move").setup({
      mappings = {
        left = "",
        right = "",
        down = "",
        up = "",
        line_left = "",
        line_right = "",
        line_down = "",
        line_up = "",
      },
      options = { reindent_linewise = true },
    })
  end,
}
