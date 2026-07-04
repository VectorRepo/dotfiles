return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",  -- ⭐ BLINK LSP SOURCE
      "b0o/schemastore.nvim", -- JSON schema validáció
    },
    config = function()
      -- MASON + AUTO LSP
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "rust_analyzer",
          "lua_ls",
          -- Web
          "ts_ls",
          "html",
          "cssls",
          "eslint",
          "emmet_language_server",
          "jsonls",
        },
        handlers = {
          ["rust_analyzer"] = function()
            require("lspconfig").rust_analyzer.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              settings = {
                ["rust-analyzer"] = {
                  checkOnSave = { command = "clippy" },
                },
              },
            })
          end,
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              settings = {
                Lua = {
                  diagnostics = { globals = { "vim" } },
                  workspace = { checkThirdParty = false },
                },
              },
            })
          end,

          -- TypeScript / JavaScript
          ["ts_ls"] = function()
            require("lspconfig").ts_ls.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              settings = {
                typescript = {
                  inlayHints = {
                    includeInlayParameterNameHints = "all",
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = false,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                  },
                },
                javascript = {
                  inlayHints = {
                    includeInlayParameterNameHints = "all",
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = false,
                  },
                },
              },
            })
          end,

          -- HTML
          ["html"] = function()
            require("lspconfig").html.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              filetypes = { "html", "htmldjango", "handlebars" },
            })
          end,

          -- CSS / SCSS / LESS
          ["cssls"] = function()
            require("lspconfig").cssls.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              settings = {
                css  = { validate = true, lint = { unknownAtRules = "ignore" } },
                scss = { validate = true, lint = { unknownAtRules = "ignore" } },
                less = { validate = true },
              },
            })
          end,

          -- ESLint (linting + fixAll on save az autocmds.lua-ban)
          ["eslint"] = function()
            require("lspconfig").eslint.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              filetypes = {
                "javascript", "javascriptreact",
                "typescript", "typescriptreact",
              },
            })
          end,

          -- Emmet (HTML/CSS gyorsbillentyűk)
          ["emmet_language_server"] = function()
            require("lspconfig").emmet_language_server.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              filetypes = {
                "html", "css", "scss",
                "javascriptreact", "typescriptreact",
              },
            })
          end,

          -- JSON + SchemaStore
          ["jsonls"] = function()
            require("lspconfig").jsonls.setup({
              capabilities = require("blink.cmp").get_lsp_capabilities(),
              settings = {
                json = {
                  schemas = require("schemastore").json.schemas(),
                  validate = { enable = true },
                },
              },
            })
          end,
        },
      })

      -- DIAGNOSTICS
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 0, winblend = 0 },
        float = { border = "rounded", winblend = 0 },
        signs = true,
        underline = true,
        update_in_insert = false,
      })

      -- ON ATTACH – itt élnek az összes LSP keymap (buffer-specifikus)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local bufopts = { noremap = true, silent = true, buffer = ev.buf }
          vim.keymap.set("n", "gd",          vim.lsp.buf.definition,    bufopts)
          vim.keymap.set("n", "K",           vim.lsp.buf.hover,         bufopts)
          vim.keymap.set("n", "<leader>vd",  vim.diagnostic.open_float, bufopts)
          vim.keymap.set("n", "]d",          vim.diagnostic.goto_next,  bufopts)
          vim.keymap.set("n", "[d",          vim.diagnostic.goto_prev,  bufopts)
          vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action,   bufopts)
          vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.rename,        bufopts)
        end,
      })
    end,
  },
}
