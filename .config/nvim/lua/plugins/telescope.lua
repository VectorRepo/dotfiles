-- ================================================================================================
-- TITLE : fzf-lua  (Telescope teljes csere)
-- Natív fzf integráció, gyorsabb mint Telescope + fzf-native
-- ================================================================================================

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    { "<leader>ff", function() require("fzf-lua").files()                       end, desc = "Find Files" },
    { "<leader>fg", function() require("fzf-lua").live_grep()                   end, desc = "Live Grep" },
    { "<leader>fb", function() require("fzf-lua").buffers()                     end, desc = "Buffers" },
    { "<leader>fh", function() require("fzf-lua").help_tags()                   end, desc = "Help Tags" },
    { "<leader>fc", function() require("fzf-lua").current_buffer_fuzzy_find()   end, desc = "Buffer Fuzzy" },
  },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      -- ---------------------------------------------------------------- globális UI
      winopts = {
        height  = 0.9,
        width   = 0.9,
        border  = "rounded",
        winblend = 0,  -- theme.lua sync: átlátszó háttér
        preview = {
          layout      = "horizontal",
          horizontal  = "right:50%",
          border      = "rounded",
          scrollbar   = false,
        },
      },

      -- ---------------------------------------------------------------- prompt / ikon
      fzf_opts = {
        ["--layout"] = "reverse",  -- prompt felül
        ["--info"]   = "inline",
      },

      -- ---------------------------------------------------------------- fájlok
      files = {
        prompt    = "   ",
        cmd       = "rg --files --hidden --glob '!**/.git/*' --glob '!**/node_modules/**'",
        git_icons = true,
        -- Ugyanazok az ignore minták mint a régi Telescope configban
        file_ignore_patterns = {
          "%.git/", "node_modules/", "%.o", "%.a", "%.out", "%.class", "%.pdf",
          "%.mkv", "%.mp4", "%.zip", "%.DS_Store", "%.png", "%.jpg", "%.gif",
        },
      },

      -- ---------------------------------------------------------------- grep
      grep = {
        prompt      = "   ",
        rg_opts     = "--hidden --glob '!**/.git/*' --column --line-number --no-heading --color=always --smart-case",
        multiline   = 0,
      },

      -- ---------------------------------------------------------------- buffers
      buffers = {
        prompt      = "   ",
        sort_lastused = true,
      },

      -- ---------------------------------------------------------------- navigáció (C-j/C-k mint régen)
      keymap = {
        fzf = {
          ["ctrl-k"] = "up",
          ["ctrl-j"] = "down",
          ["ctrl-u"] = "preview-page-up",
          ["ctrl-d"] = "preview-page-down",
        },
      },

      -- ---------------------------------------------------------------- ui-select csere (volt: telescope-ui-select)
      -- vim.ui.select → fzf-lua dropdown
    })

    -- vim.ui.select → fzf-lua (volt: telescope-ui-select)
    fzf.register_ui_select(function(_, items)
      local min_h = math.max(3, #items + 2)
      return {
        winopts = {
          height  = min_h,
          width   = 50,
          border  = "rounded",
          winblend = 0,
        },
      }
    end)
  end,
}
