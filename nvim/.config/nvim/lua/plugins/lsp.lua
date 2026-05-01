vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
vim.pack.add({ "https://github.com/mason-org/mason.nvim" })
vim.pack.add({ "https://github.com/aznhe21/actions-preview.nvim" })

require("mason").setup()

require("actions-preview").setup({
  backend = { "telescope" },
  extensions = { "env" },
  telescope = vim.tbl_extend("force", require("telescope.themes").get_dropdown(), {}),
})

local orig_open_floating_preview   = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or "rounded"
  return orig_open_floating_preview(contents, syntax, opts, ...)
end

vim.o.pumborder                    = "rounded"
vim.opt.completeopt                = { "menuone", "noselect", "popup" }

vim.lsp.enable({
  "lua_ls", "ts_ls", "cssls", "tailwindcss",
  "svelte", "emmet_language_server", "emmet_ls",
  "rust_analyzer", "clangd", "zls",
  "ruff", "pyright",
  "haskell-language-server", "hlint",
  "intelephense", "solargraph",
  "tinymist", "glsl_analyzer",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr  = args.buf
    local map    = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    -- Native insert-mode auto-completion
    if client:supports_method("textDocument/completion") then
      -- Trigger completion on every printable character
      local chars = {}
      for i = 32, 126 do table.insert(chars, string.char(i)) end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end

    map("n", "<leader>lk", function()
      vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
    end, "toggle inline diagnostics")

    map("n", "<leader>ln", vim.diagnostic.goto_next, "next diagnostic")
    map("n", "<leader>lp", vim.diagnostic.goto_prev, "prev diagnostic")

    map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "format buffer")
    map({ "n", "v" }, "ca", require("actions-preview").code_actions, "code actions (preview)")
    map("n", "<leader>rn", vim.lsp.buf.rename, "rename symbol")
    map("n", "K", vim.lsp.buf.hover, "hover docs")
  end,
})
