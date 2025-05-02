return {
  -- completion engine
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        menu = {
          border = "rounded",
          winhighlight =
          "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
        },
        documentation = {
          auto_show = true,
          window = {
            border = "rounded",
          },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" }

    },
    opts_extend = { "sources.default" }
  },

  { "williamboman/mason.nvim", config = true },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")


      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, "LSP: Format Document")
        map('n', '<leader>rn', vim.lsp.buf.rename, "LSP: Rename Symbol")
        map('n', 'gd', require('telescope.builtin').lsp_definitions, "LSP: Go to Definition")
        map('n', 'gr', require('telescope.builtin').lsp_references, "LSP: Go to References")
        map('n', 'gD', vim.lsp.buf.declaration, "LSP: Go to Declaration")
        map('n', 'gi', vim.lsp.buf.implementation, "LSP: Go to Implementation")
        map('n', 'gt', vim.lsp.buf.type_definition, "LSP: Go to Type Definition")
        map('n', 'K', vim.lsp.buf.hover, "LSP: Hover Documentation")
        map('n', '<C-k>', vim.lsp.buf.signature_help, "LSP: Signature Help")
        map('n', '<leader>lk', vim.diagnostic.open_float, "LSP: Floating Diagnostic")
        map('n', '<leader>ln', vim.diagnostic.goto_next, "LSP: Next Diagnostic")
        map('n', '<leader>lp', vim.diagnostic.goto_prev, "LSP: Previous Diagnostic")
        map('n', '<leader>ca', vim.lsp.buf.code_action, "LSP: Code Action")
        map('n', '<leader>ls', vim.lsp.buf.document_symbol, "LSP: Document Symbols")
        map('n', '<leader>lS', vim.lsp.buf.workspace_symbol, "LSP: Workspace Symbols")
      end

      require("mason").setup()
      mason_lspconfig.setup()

      -- automatically setup all installed lsp servers
      mason_lspconfig.setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            on_attach = on_attach,
          })
        end,
      })
    end,
  },
}
