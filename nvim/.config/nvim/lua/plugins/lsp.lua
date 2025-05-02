return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "jcha0713/cmp-tw2css",
        "hrsh7th/nvim-cmp",
    },

    config = function()
        -- Consistent ronding for boders
        vim.diagnostic.config({
            float = { border = "rounded" }
        })

        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("mason").setup()
        require("mason-lspconfig").setup({
            automatic_installation = false,
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "tinymist",
            },
            handlers = {
                function(server_name)
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,
                ["svelte"] = function()
                    require("lspconfig")["svelte"].setup({
                        capabilities = capabilities,
                        on_attach = function(client, bufnr)
                            vim.api.nvim_create_autocmd("BufWritePost", {
                                pattern = { "*.js", "*.ts" },
                                callback = function(ctx)
                                    -- this bad boy updates imports between svelte and ts/js files
                                    client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                                end,
                            })
                        end
                    })
                end,
                ["tinymist"] = function()
                    require("lspconfig")["tinymist"].setup {
                        capabilities = capabilities,
                        settings = {
                            formatterMode = "typstyle",
                            exportPdf = "never"
                        },
                    }
                end,
                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end
            }

        })
        local l = vim.lsp
        l.handlers["textDocument/hover"] = function(_, result, ctx, config)
            config = config or { border = "rounded", focusable = true }
            config.focus_id = ctx.method
            if not (result and result.contents) then
                return
            end
            local markdown_lines = l.util.convert_input_to_markdown_lines(result.contents)
            markdown_lines = vim.tbl_filter(function(line)
                return line ~= ""
            end, markdown_lines)
            if vim.tbl_isempty(markdown_lines) then
                return
            end
            return l.util.open_floating_preview(markdown_lines, "markdown", config)
        end

        local cmp_select = { behavior = cmp.SelectBehavior.Select }
        vim.api.nvim_set_hl(0, "CmpNormal", {})
        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ['<C-e>'] = vim.NIL
            }),

            window = {
                completion = {
                    scrollbar = false,
                    border = "rounded",
                    winhighlight = "Normal:CmpNormal",
                },
                documentation = {
                    scrollbar = false,
                    border = "rounded",
                    winhighlight = "Normal:CmpNormal",
                }
            },
            sources = cmp.config.sources({
                {
                    name = "nvim_lsp",
                    entry_filter = function(entry, ctx)
                        return require("cmp").lsp.CompletionItemKind.Snippet ~= entry:get_kind()
                    end,
                },
                { name = 'cmp-tw2css' },
            }, {})
        })


        local autocmd = vim.api.nvim_create_autocmd
        autocmd({ "BufEnter", "BufWinEnter" }, {
            pattern = { "*.vert", "*.frag" },
            callback = function(e)
                vim.cmd("set filetype=glsl")
            end

        })

        autocmd('LspAttach', {
            callback = function(e)
                local opts = { buffer = e.buf }
                vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
                vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
                vim.keymap.set("n", "<leader>la", function() vim.lsp.buf.code_action() end, opts)
                vim.keymap.set("n", "<leader>lr", function() vim.lsp.buf.rename() end, opts)
                vim.keymap.set("n", "<leader>lk", function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set("n", "<leader>ln", function() vim.diagnostic.goto_next() end, opts)
                vim.keymap.set("n", "<leader>lp", function() vim.diagnostic.goto_prev() end, opts)
                vim.keymap.set("n", "gr", require('telescope.builtin').lsp_references, opts)
            end
        })
    end
}

-- return {
--   {
--     'saghen/blink.cmp',
--     dependencies = { 'rafamadriz/friendly-snippets' },
--     version = '1.*',
--     opts = {
--       keymap = { preset = 'default' },
--       appearance = { nerd_font_variant = 'mono' },
--       completion = {
--         documentation = { auto_show = false },
--         menu = { border = "rounded", winblend = 0 }
--       },
--       sources = {
--         default = { 'lsp', 'path', 'snippets', 'buffer' },
--       },
--       fuzzy = { implementation = "prefer_rust_with_warning" },
--     },
--     opts_extend = { "sources.default" }
--   },
--   {
--     -- mason lsp installer
--     "williamboman/mason.nvim",
--     config = function()
--       require('mason').setup({
--         ui = {
--           icons = {
--             package_installed = "✓",
--             package_pending = "➜",
--             package_uninstalled = "✗"
--           }
--         }
--       })
--     end,
--   },
--   {
--     -- mason lsp config and lsp setup
--     "williamboman/mason-lspconfig.nvim",
--     dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
--     config = function()
--       -- diagnostic display configuration
--       vim.diagnostic.config({
--         virtual_text = true,
--         signs = true,
--         underline = true,
--         update_in_insert = false,
--         severity_sort = true,
--         float = { border = "rounded", source = "always", },
--       })
--
--       -- diagonstics remaps
--       local opts = { noremap = true, silent = true }
--       vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
--       vim.keymap.set('n', '<leader>lp', vim.diagnostic.goto_prev, opts)
--       vim.keymap.set('n', '<leader>ln', vim.diagnostic.goto_next, opts)
--       vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, opts)
--
--       require('mason-lspconfig').setup({
--         ensure_installed = { 'ts_ls', 'pylsp', 'lua_ls', 'rust_analyzer' },
--         automatic_installation = true,
--       })
--
--       local lspconfig = require('lspconfig')
--       local on_attach = function(client, bufnr)
--         local bufopts = { noremap = true, silent = true, buffer = bufnr }
--         vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
--         vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
--         vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, bufopts)
--         vrm.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
--         vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
--         vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help, bufopts)
--         vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
--         vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
--         vim.keymap.set('n', '<leader>wl', function()
--           print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--         end, bufopts)
--         vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
--         vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, bufopts)
--         vim.keymap.set('n', '<leader>lc', vim.lsp.buf.code_action, bufopts)
--         vim.keymap.set("n", '<leader>lf', function()
--           vim.lsp.buf.format({ async = true })
--         end, bufopts)
--       end
--
--       require("mason-lspconfig").setup_handlers {
--         function(server_name)
--           lspconfig[server_name].setup {
--             on_attach = on_attach,
--             handlers = {
--               ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
--               ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
--             }
--           }
--         end
--       }
--     end
--   }
-- }
