vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" })


vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'svelte', 'markdown', 'lua', 'rust', 'typst', 'typescript', 'javascript', 'c', 'cpp', 'glsl', 'zig', 'python', "typescriptreact", "react", },
	callback = function() vim.treesitter.start() end,
})

