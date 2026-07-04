return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd   = { "ConformInfo" },
  keys  = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_fallback = true }) end,
      mode = { "n", "v" },
      desc = "Format file / selection",
    },
  },
  opts = {
    -- Prettier fut JS/TS/HTML/CSS/JSON fájlokon
    formatters_by_ft = {
      javascript      = { "prettier" },
      javascriptreact = { "prettier" },
      typescript      = { "prettier" },
      typescriptreact = { "prettier" },
      html            = { "prettier" },
      css             = { "prettier" },
      scss            = { "prettier" },
      json            = { "prettier" },
      jsonc           = { "prettier" },
      markdown        = { "prettier" },
      yaml            = { "prettier" },
    },

    -- Mentéskor automatikusan formáz (500ms timeout)
    format_on_save = function(bufnr)
      -- Ha van .prettierrc / prettier.config.js a projektben, használja
      -- Ha nincs, a beépített alapértékekkel fut
      return {
        timeout_ms   = 500,
        lsp_fallback = true,
      }
    end,

    -- Prettier beállítások (ha nincs .prettierrc a projektben)
    formatters = {
      prettier = {
        prepend_args = {
          "--single-quote",
          "--jsx-single-quote",
          "--trailing-comma", "es5",
          "--print-width",    "100",
          "--tab-width",      "2",
        },
      },
    },
  },

  -- Mason auto-telepíti a prettier-t
  init = function()
    -- Jelzi a conform-nak, hogy Mason-ból vegye a prettier-t
    vim.g.conform_mason = true
  end,
}
