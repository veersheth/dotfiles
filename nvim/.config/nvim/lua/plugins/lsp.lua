-- grn: vim.lsp.buf.rename()
-- grr: vim.lsp.buf.references()
-- gra: vim.lsp.buf.code_actions()
-- gd: vim.lsp.buf.definition()
-- ln: next diagonostic
-- lp: prev diagonostic
-- lf: format document
-- lh: toggle inlay hints 

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "lua_ls", "svelte", "tinymist", "rust_analyzer",
        "tailwindcss", "ts_ls", "pyright", "clangd"
      }
    }
  },
  {
    "neovim/nvim-lspconfig",
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
      {
        "williamboman/mason-lspconfig.nvim",
        opts = {
          automatic_installation = true,
          ensure_installed = {
            "lua_ls", "svelte", "tinymist", "rust_analyzer",
            "tailwindcss", "ts_ls", "pyright"
          }
        },
      }
    },
    config = function()
      vim.lsp.enable({
        lua_ls,
        svelte,
        tinymist,
        rust_analyzer,
        tailwindcss,
        ts_ls,
        pyright,
      })

      vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "format" })
      vim.keymap.set("n", "<leader>lp", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "prev diagonostic" })
      vim.keymap.set("n", "<leader>ln", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "next diagnostic" })
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { desc = "go to definition" })

      vim.keymap.set("n", "<leader>lh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = "toggle inline hints" })

      --   -- auto command for omnicomplete
      --   vim.api.nvim_create_autocmd('LspAttach', {
      --     callback = function(ev)
      --       local client = vim.lsp.get_client_by_id(ev.data.client_id)
      --       if client:supports_method('textDocument/completion') then
      --         vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      --       end
      --     end
      --     ,
      --   })
      --   vim.cmd("set completeopt+=noselect")
    end
  },
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = {
        preset = 'default',
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = "lua" },
    },
    opts_extend = { "sources.default" }
  },

  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = {
        ['<CR>'] = { 'accept', 'fallback' }
      },
      appearance = { nerd_font_variant = 'mono' },

      completion = { documentation = { auto_show = true } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = "prefer_rust" }
    },
    opts_extend = { "sources.default" }
  }
}
