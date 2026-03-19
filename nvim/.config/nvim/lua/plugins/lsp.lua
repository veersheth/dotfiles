return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					local builtin = require("telescope.builtin")

					map("grr", builtin.lsp_references, "references")
					map("gd", builtin.lsp_definitions, "definitions")
					map("gi", builtin.lsp_implementations, "implementations")
					map("<leader>ds", builtin.lsp_document_symbols, "doc symbols")

					map("grn", vim.lsp.buf.rename, "smart rename")
					map("gra", vim.lsp.buf.code_action, "code actions")

					map("<leader>lf", function()
						vim.lsp.buf.format({ async = true })
					end, "format document")

					map("<leader>ln", function()
						vim.diagnostic.goto_next()
					end, "next diagnostic")

					map("<leader>lp", function()
						vim.diagnostic.goto_prev()
					end, "prev diagnostic")

					map("<leader>lk", function()
						local current = vim.diagnostic.config().virtual_text
						vim.diagnostic.config({ virtual_text = not current })
					end, "toggle hover diagnostics")

					if client and client:supports_method("textDocument/documentSymbol") then
						require("nvim-navic").attach(client, event.buf)
					end
				end,
			})

			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { globals = { "vim" } },
						},
					},
				},
				-- rust_analyzer = {},
			}

			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "rust_analyzer", "ts_ls", "pyright", "svelte" },
				handlers = {
					function(server_name)
						local server_opts = servers[server_name] or {}
						server_opts.capabilities =
							vim.tbl_deep_extend("force", capabilities, server_opts.capabilities or {})

						vim.lsp.config(server_name, server_opts)
						vim.lsp.enable(server_name)
					end,
				},
			})
		end,
	},
	{
		"saghen/blink.cmp",
		opts = {
			keymap = { preset = "default" },

			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},

			signature = { enabled = true },
		},
		opts_extend = { "sources.default" },
	},
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				rust = { "rustfmt" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
			},
		},
	},
}
