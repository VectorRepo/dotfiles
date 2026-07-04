return {
  {
    "echasnovski/mini.base16",
    lazy = false,
    priority = 1000,
    config = function()

      local matugen_path = os.getenv("HOME") .. "/.config/nvim/neovim-colors.lua"

      local default_colors = {
        base00 = "#1e1e2e", base01 = "#181825", base02 = "#313244", base03 = "#45475a",
        base04 = "#585b70", base05 = "#cdd6f4", base06 = "#f5e0dc", base07 = "#b4befe",
        base08 = "#f38ba8", base09 = "#fab387", base0A = "#f9e2af", base0B = "#a6e3a1",
        base0C = "#94e2d5", base0D = "#89b4fa", base0E = "#cba6f7", base0F = "#f2cdcd",
      }

      local function read_base0B()
        local f = io.open(matugen_path, "r")
        if not f then return default_colors.base0B end
        local content = f:read("*a")
        f:close()
        return content:match("base0B%s*=%s*[\"'](%#%x%x%x%x%x%x)[\"']") or default_colors.base0B
      end

      local function load_theme()
        if vim.uv.fs_stat(matugen_path) then
          local ok, err = pcall(dofile, matugen_path)
          if not ok then
            vim.notify("Matugen Error: " .. err, vim.log.levels.ERROR)
            require("base16-colorscheme").setup(default_colors)
          end
        else
          vim.notify("Matugen not found, using defaults", vim.log.levels.WARN)
          require("base16-colorscheme").setup(default_colors)
        end
      end

      local function apply_tweaks()
        local primary = read_base0B()

        -- Float ablakok: NONE háttér = terminál háttér látszik át
        -- FONTOS: Normal-t NE állítsuk NONE-ra, mert az a szöveget is tönkreteszi.
        -- A blink winhighlight Normal:BlinkCmpMenu → BlinkCmpMenu NONE = átlátszó.
        -- A pumblend=0 (options.lua) gondoskodik a popup átlátszóságáról.
        local transparent = {
          "NormalFloat", "FloatBorder", "MsgArea",
          "BlinkCmpMenu",    "BlinkCmpMenuBorder",
          "BlinkCmpDoc",     "BlinkCmpDocBorder",     "BlinkCmpDocCursorLine",
          "BlinkCmpSignatureHelp", "BlinkCmpSignatureHelpBorder",
          "FzfLuaNormal",    "FzfLuaBorder",
          "FzfLuaPreviewNormal", "FzfLuaPreviewBorder",
          "Pmenu",           "PmenuSbar",
          "SignColumn", "LineNr", "EndOfBuffer", "WinBar", "WinBarNC",
        }
        for _, g in ipairs(transparent) do
          vim.api.nvim_set_hl(0, g, { bg = "NONE", ctermbg = "NONE" })
        end

        -- Border szín = primary (base0B)
        for _, g in ipairs({
          "FloatBorder", "BlinkCmpMenuBorder", "BlinkCmpDocBorder",
          "BlinkCmpSignatureHelpBorder", "FzfLuaBorder", "FzfLuaPreviewBorder",
        }) do
          vim.api.nvim_set_hl(0, g, { fg = primary, bg = "NONE" })
        end

        -- Kijelölés
        vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { bg = primary, fg = "#1e1e2e", bold = true })
        vim.api.nvim_set_hl(0, "BlinkCmpDocCursorLine", { bg = primary, fg = "#1e1e2e" })
        vim.api.nvim_set_hl(0, "FzfLuaSel",             { bg = primary, fg = "#1e1e2e", bold = true })
        vim.api.nvim_set_hl(0, "PmenuSel",              { bg = primary, fg = "#1e1e2e", bold = true })

        -- Egyéb
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3b4252" })
        vim.api.nvim_set_hl(0, "Comment",    { italic = true })
        vim.opt.guicursor = "n-v-c:hor20-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
      end

      load_theme()
      apply_tweaks()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_tweaks,
      })

      local signal = vim.uv.new_signal()
      signal:start("sigusr1", function()
        vim.schedule(function()
          load_theme()
          apply_tweaks()
          vim.notify("✅ Matugen újratöltve!")
        end)
      end)
    end,
  },
}
