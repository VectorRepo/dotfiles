-- ================================================================================================
-- TITLE : mini.statusline
-- mini.nvim már úgyis betöltődik → nincs extra plugin overhead
-- Színek: matugen tokenek alapján, theme.lua apply_tweaks()-szal szinkronban
-- ================================================================================================

return {
  "echasnovski/mini.statusline",
  version = false,
  event = "VeryLazy",
  config = function()
    local statusline = require("mini.statusline")

    -- ── Highlight csoportok beállítása ────────────────────────────────────────
    -- Matugen tokenek → ugyanazok mint a template.lua-ban
    -- A theme.lua SIGUSR1 jelnél újratölti a színeket → itt is frissíteni kell
    local function apply_statusline_hl()
      local matugen_path = os.getenv("HOME") .. "/.config/matugen/generated/neovim-colors.lua"

      -- Matugen színek kiolvasása (ugyanaz a logika mint theme.lua-ban)
      local colors = {
        bg           = "#1e1e2e", -- base00 / background
        bg_inactive  = "#181825", -- base01 / surface_container_lowest
        primary      = "#a6e3a1", -- base0B / primary
        secondary    = "#f9e2af", -- base0A / secondary
        tertiary     = "#fab387", -- base09 / tertiary
        error        = "#f38ba8", -- base08 / error
        on_surface   = "#cdd6f4", -- base05 / on_surface
        outline      = "#45475a", -- base03 / outline_variant
      }

      local f = io.open(matugen_path, "r")
      if f then
        local content = f:read("*a")
        f:close()
        local function hex(token)
          return content:match(token .. "%s*=%s*['\"](%#%x%x%x%x%x%x)['\"]")
        end
        colors.bg          = hex("base00") or colors.bg
        colors.bg_inactive = hex("base01") or colors.bg_inactive
        colors.primary     = hex("base0B") or colors.primary
        colors.secondary   = hex("base0A") or colors.secondary
        colors.tertiary    = hex("base09") or colors.tertiary
        colors.error       = hex("base08") or colors.error
        colors.on_surface  = hex("base05") or colors.on_surface
        colors.outline     = hex("base03") or colors.outline
      end

      -- MiniStatusline szegmens highlight csoportok
      -- *Mode*  = aktuális mód (primary színnel kiemelve)
      -- *File*  = fájlnév + módosítás jelző
      -- *Info*  = LSP hibák/warningok
      -- *Git*   = git branch (ha gitsigns telepítve lesz)
      -- *inactive* = nem aktív ablak

      vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal",  { bg = colors.primary,     fg = colors.bg,         bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert",  { bg = colors.secondary,   fg = colors.bg,         bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual",  { bg = colors.tertiary,    fg = colors.bg,         bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { bg = colors.error,       fg = colors.bg,         bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { bg = colors.outline,     fg = colors.on_surface, bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineModeOther",   { bg = colors.outline,     fg = colors.on_surface, bold = true })

      vim.api.nvim_set_hl(0, "MiniStatuslineFilename",    { bg = "NONE",             fg = colors.on_surface })
      vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo",    { bg = "NONE",             fg = colors.outline    })
      vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo",     { bg = "NONE",             fg = colors.primary    })
      vim.api.nvim_set_hl(0, "MiniStatuslineInactive",    { bg = "NONE",             fg = colors.outline    })
    end

    apply_statusline_hl()

    -- Újraalkalmaz ha a téma változik (matugen SIGUSR1 → ColorScheme event)
    vim.api.nvim_create_autocmd("ColorScheme", {
      group    = vim.api.nvim_create_augroup("StatuslineColors", { clear = true }),
      callback = apply_statusline_hl,
    })

    -- ── Statusline tartalom ───────────────────────────────────────────────────
    statusline.setup({
      use_icons = true,

      content = {
        active = function()
          local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
          local git           = statusline.section_git({ trunc_width = 75 })
          local diff          = statusline.section_diff({ trunc_width = 75 })
          local diagnostics   = statusline.section_diagnostics({ trunc_width = 75 })
          local filename      = statusline.section_filename({ trunc_width = 140 })
          local fileinfo      = statusline.section_fileinfo({ trunc_width = 120 })
          local location      = statusline.section_location({ trunc_width = 75 })
          local search        = statusline.section_searchcount({ trunc_width = 75 })

          return statusline.combine_groups({
            { hl = mode_hl,                   strings = { mode } },
            { hl = "MiniStatuslineDevinfo",   strings = { git, diff } },
            "%<", -- csonkítási pont: ha szűk az ablak, itt vágja le
            { hl = "MiniStatuslineFilename",  strings = { filename } },
            "%=", -- jobb oldal kezdete
            { hl = "MiniStatuslineFileinfo",  strings = { diagnostics, fileinfo } },
            { hl = mode_hl,                   strings = { search, location } },
          })
        end,

        -- Inaktív ablakban: csak fájlnév, halvány
        inactive = function()
          return statusline.combine_groups({
            { hl = "MiniStatuslineInactive", strings = { "%f %m" } },
          })
        end,
      },
    })
  end,
}
