local vim = vim

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------

vim.pack.add({ "https://github.com/mason-org/mason.nvim" })
require("mason").setup()

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------

vim.pack.add({ "https://github.com/Saghen/blink.lib" })
vim.pack.add({ { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('*') } })


require("blink.cmp").setup({
  keymap = { preset = "default" },
  fuzzy = { implementation = "lua" },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
})

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------

vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
vim.pack.add({ "https://github.com/mason-org/mason-lspconfig.nvim" })
vim.pack.add({ "https://github.com/aznhe21/actions-preview.nvim" })

require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls", "ts_ls", "cssls",
    "html",
    "emmet_ls",
    "svelte",
    "rust_analyzer", "clangd",
    "ruff", "pyright",
    "tinymist",
  },
  automatic_enable = false,
})

vim.lsp.config("harper_ls", {
  filetypes = { "markdown" },
  root_dir = function(bufnr, on_dir)
    local vault = vim.fn.expand("~/sync/vault")
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path:sub(1, #vault + 1) == vault .. "/" then on_dir(vault) end
  end,
  settings = {
    ["harper-ls"] = {
      dialect = "Australian",
      linters = {
        SentenceCapitalization = false,
        CapitalizePersonalPronouns = false,
        OrthographicConsistency = false,
      },
    },
  },
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and result.diagnostics then
        local bufnr = vim.uri_to_bufnr(result.uri)
        if vim.api.nvim_buf_is_loaded(bufnr) then
          result.diagnostics = vim.tbl_filter(function(diagnostic)
            if diagnostic.code ~= "SpellCheck" then return true end
            local range = diagnostic.range
            if range.start.line ~= range["end"].line then return true end
            local line = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range.start.line + 1, false)[1]
            if not line then return true end
            local start = vim.str_byteindex(line, "utf-16", range.start.character, false)
            local finish = vim.str_byteindex(line, "utf-16", range["end"].character, false)
            local word = line:sub(start + 1, finish)
            if not word:match("^%l+$") then return true end
            return vim.api.nvim_buf_call(bufnr, function()
              return #vim.spell.check(word:sub(1, 1):upper() .. word:sub(2)) > 0
                and #vim.spell.check(word:upper()) > 0
            end)
          end, result.diagnostics)
        end
      end
      return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
    end,
  },
})

require("actions-preview").setup({
  backend = { "telescope" },
  extensions = { "env" },
  telescope = vim.tbl_extend("force", require("telescope.themes").get_dropdown(), {}),
})

vim.lsp.enable({
  "lua_ls", "ts_ls", "cssls",
  "svelte",
  "rust_analyzer", "clangd",
  "ruff", "pyright",
  "tinymist", 
  "emmet_ls", "harper_ls"
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),

  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr  = args.buf
    local map    = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    map("n", "<leader>lk", function()
      vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
    end, "toggle inline diagnostics")
    map("n", "<leader>ln", vim.diagnostic.goto_next, "next diagnostic")
    map("n", "<leader>lp", vim.diagnostic.goto_prev, "prev diagnostic")
    map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "format buffer")

    map("n", "gd", vim.lsp.buf.definition, "go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "go to declaration")
    map("n", "gr", vim.lsp.buf.references, "go to references")
    map("n", "gi", vim.lsp.buf.implementation, "go to implementation")
    map({ "n", "v" }, "<leader>ca", require("actions-preview").code_actions, "code actions (preview)")
    map("n", "<leader>rn", vim.lsp.buf.rename, "rename symbol")
  end,
})
