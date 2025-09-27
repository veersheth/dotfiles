-- grn: vim.lsp.buf.rename()
-- grr: vim.lsp.buf.references()
-- gra: vim.lsp.buf.code_actions()

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "lua_ls", "svelte", "tinymist", "rust_analyzer",
        "tailwindcss", "ts_ls", "pyright"
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
      require("lspconfig").lua_ls.setup({})
      require("lspconfig").svelte.setup({})
      require("lspconfig").tinymist.setup({})
      require("lspconfig").rust_analyzer.setup({})
      require("lspconfig").tailwindcss.setup({})
      require("lspconfig").ts_ls.setup({})
      require("lspconfig").pyright.setup({})

      vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
      vim.keymap.set("n", "<leader>lp", vim.diagnostic.goto_prev)
      vim.keymap.set("n", "<leader>ln", vim.diagnostic.goto_next)

      -- auto command for omnicomplete
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
          end
        end
        ,
      })
      vim.cmd("set completeopt+=noselect")
    end
  }
}
