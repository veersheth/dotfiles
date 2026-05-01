vim.pack.add({ "https://github.com/L3MON4D3/LuaSnip" })

require "luasnip".setup({ enable_autosnippets = true })
require "luasnip.loaders.from_lua".load({ paths = "~/.config/nvim/snippets/" })
