return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },

  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {

    keymap = {
      preset = "none",
      ["<C-Space>"] = { "show", "fallback" },
      ["<C-e>"]     = { "cancel", "fallback" },
      ["<CR>"]      = { "accept", "fallback" },
      ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
      ["<Down>"]    = { "select_next", "fallback" },
      ["<Up>"]      = { "select_prev", "fallback" },
      ["<C-j>"]     = { "scroll_documentation_down", "fallback" },
      ["<C-k>"]     = { "scroll_documentation_up",   "fallback" },
    },

    completion = {
      -- preselect = false → Enter csak akkor fogad el ha Tab-bal kiválasztottad
      -- auto_insert = false → nem írja be automatikusan a szöveget navigáláskor
      list = { selection = { preselect = false, auto_insert = false } },

      menu = {
        enabled    = true,
        min_width  = 44,
        max_height = math.max(8, math.floor(vim.o.lines * 0.35)),
        border     = "rounded",
        winblend   = 0,
        scrollbar  = false,
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

        draw = {
          columns = {
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "source_name" },
          },
          components = {
            label = {
              text = function(ctx)
                return vim.fn.strcharpart(ctx.label, 0, 48)
              end,
            },
            source_name = {
              text = function(ctx)
                local names = {
                  LSP      = "LSP",
                  Path     = "PATH",
                  Snippets = "SNIP",
                  Buffer   = "BUF",
                  lazydev  = "DEV",
                }
                return names[ctx.source_name] or ctx.source_name
              end,
            },
          },
        },
      },

      documentation = {
        auto_show          = true,
        auto_show_delay_ms = 100,
        window = {
          border       = "rounded",
          winblend     = 0,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
          max_width  = math.max(60, math.floor(vim.o.columns * 0.50)),
          max_height = math.max(10, math.floor(vim.o.lines   * 0.40)),
        },
      },

      ghost_text = { enabled = false },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        buffer = { min_keyword_length = 3 },
        lazydev = {
          name         = "lazydev",
          module       = "lazydev.integrations.blink",
          score_offset = 100,
        },
      },
    },

    snippets = { preset = "default" },

    fuzzy = {
      implementation = "prefer_rust_with_warning",
      frecency = { enabled = true },
      sorts    = { "score", "sort_text", "label", "kind" },
    },

    cmdline = {
      enabled = true,
      keymap  = { preset = "cmdline" },
      completion = {
        list = { selection = { preselect = false, auto_insert = true } },
      },
    },

    signature = {
      enabled = true,
      window  = { border = "rounded", winblend = 0 },
    },
  },
}
