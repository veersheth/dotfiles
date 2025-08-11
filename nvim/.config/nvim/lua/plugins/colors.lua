-- return {
--     "https://github.com/aktersnurra/no-clown-fiesta.nvim.git",
--     config = function() 
--         require("no-clown-fiesta").setup({
--           transparent = true, -- Enable this to disable the bg color
--           styles = {
--             comments = {},
--             functions = {},
--             keywords = {},
--             lsp = {},
--             match_paren = {},
--             type = {},
--             variables = {},
--           },
--         })
--     end
-- }
return {
    "vague2k/vague.nvim",
    config = function()
        require("vague").setup({ transparent = true })
        vim.cmd("colorscheme vague")
        vim.cmd(":hi statusline guibg=NONE")
    end
}
