local autosave_group = vim.api.nvim_create_augroup("Autosave", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = autosave_group,
    pattern = "*.typ", 
    command = "silent! write",
})
