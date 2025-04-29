return {
  -- Mason plugin for LSP management
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",    -- Update Mason when plugin is loaded
    cmd = "Mason",             -- Mason command is available in the command line
    config = function()
      require("mason").setup() -- Corrected the typo here
    end,
  },

  -- Mason-lspconfig plugin to integrate Mason with lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "bashls", -- Add any LSP servers you need
        },
        automatic_installation = true,                                       -- Automatically install missing servers
      })
    end,
  },

  -- LSP Configuration for Neovim
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      local telescope_builtin = require("telescope.builtin")
      local cmp = require("cmp")

      -- Setup capabilities for nvim-cmp
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- on_attach function to map LSP commands
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true }
        local function map(mode, lhs, rhs)
          vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
        end

        map("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>")

        -- Telescope-powered mappings
        map("n", "gd", "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>")
        map("n", "gr", "<cmd>lua require('telescope.builtin').lsp_references()<CR>")
        map("n", "gi", "<cmd>lua require('telescope.builtin').lsp_implementations()<CR>")
        map("n", "gt", "<cmd>lua require('telescope.builtin').lsp_type_definitions()<CR>")

        -- LSP core
        map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
        map("n", "<leader><leader>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
        map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
        map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>")

        -- Workspace symbols
        map("n", "<leader>ds", "<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>")
        map("n", "<leader>ws", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>")

        -- Diagnostics
        map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
        map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>")
        map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>")
        map("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>")
      end

      local servers = {
        "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "bashls",
      }

      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- Sign symbols for diagnostics
      local signs = { Error = "✘", Warn = "▲", Hint = "⚑", Info = "" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Diagnostics configuration
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })
    end,
  },

  -- Autocompletion with nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body) -- Using luasnip for snippet expansion
          end,
        },
        mapping = {
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.close(),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
        },
      })
    end,
  },

  -- Performance optimization for Telescope references
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          prompt_prefix = "🔍 ",
          selection_caret = "➤ ",
          layout_strategy = "horizontal",
          layout_config = {
            width = 0.8,
            height = 0.8,
            preview_width = 0.6,
          },
          sorting_strategy = "ascending",
          file_ignore_patterns = { "node_modules", ".git" },
        },
      })

      -- Optimize the references command (uses `lsp_references` more efficiently)
      local builtin = require("telescope.builtin")
      builtin.lsp_references = function(opts)
        opts = opts or {}
        opts.telescope_sorter = require("telescope.sorters").get_fuzzy_file
        builtin.lsp_references(opts)
      end
    end,
  },

  -- Highlight word when hovering (for 400ms)
  -- Highlight word when hovering (for 400ms)
  -- {
  --   "nvim-lua/plenary.nvim",
  --   config = function()
  --     vim.api.nvim_create_autocmd("CursorHold", {
  --       callback = function()
  --         local word = vim.fn.expand("<cword>")
  --         -- Highlight the word and store the match ID
  --         local match_id = vim.fn.matchadd("Search", word, 10)
  --         vim.defer_fn(function()
  --           -- Remove the highlight after 400ms using the match ID
  --           vim.fn.matchdelete(match_id)
  --         end, 400)
  --       end,
  --     })
  --   end,
  -- },

}
