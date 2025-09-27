return {
    'nvim-mini/mini.pick',
    version = false,
    config = function()
        require("mini.pick").setup({
            mappings = { choose_marked = "<leader>fm" }
        })

        vim.keymap.set('n', '<leader>fp', ":Pick resume<CR>", { desc = "Continue picking" })
        vim.keymap.set('n', '<leader>fd', ":Pick files<CR>", { desc = "Search files" })
        vim.keymap.set('n', '<leader>fs', ":Pick grep_live<CR>", { desc = "Search grep" })
        vim.keymap.set('n', '<leader>fh', ":Pick help<CR>", { desc = "Search help" })
    end
}
