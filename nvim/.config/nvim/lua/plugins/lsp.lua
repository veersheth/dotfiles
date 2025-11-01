-- grn: vim.lsp.buf.rename()
-- grr: vim.lsp.buf.references()
-- gra: vim.lsp.buf.code_actions()
-- gd: vim.lsp.buf.definition()

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

      vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "format doc" })
      vim.keymap.set("n", "<leader>lp", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "prev diagnostic" })
      vim.keymap.set("n", "<leader>ln", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "next diagnostic" })
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { desc = "go to definition" })

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
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },

      -- (Default) Only show the documentation popup when manually triggered
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      -- fuzzy = { implementation = "prefer_rust" }
      fuzzy = { implementation = "lua" }
    },
    opts_extend = { "sources.default" }
  }
}
