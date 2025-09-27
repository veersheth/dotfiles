-- typst zathura preview
vim.keymap.set("n", "<leader>tp", function()
    local file = vim.fn.expand("%:p")
    local pdf  = vim.fn.expand("%:r") .. ".pdf"
    local cmd  = string.format("typst watch %s & zathura %s", file, pdf)
    vim.fn.jobstart({ "bash", "-c", cmd }, { detach = true })
end, { desc = "Typst / Zathura preview" })

-- writing mode
local writing_mode = false

vim.keymap.set("n", "<leader>w", function()
    writing_mode = not writing_mode

    if writing_mode then
        vim.opt_local.wrapmargin = 10
        vim.opt_local.formatoptions:append("t")
        vim.opt_local.linebreak = true
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        -- fake margins
        vim.opt_local.foldcolumn = "4"
        vim.opt_local.signcolumn = "yes:1"
        vim.notify("Writing mode enabled", vim.log.levels.INFO)
    else
        vim.opt_local.wrapmargin = 0
        vim.opt_local.formatoptions:remove("t")
        vim.opt_local.linebreak = false
        vim.opt_local.wrap = false
        vim.opt_local.spell = false
        -- reset margins
        vim.opt_local.foldcolumn = "0"
        vim.opt_local.signcolumn = "yes"
        vim.notify("Writing mode disabled", vim.log.levels.INFO)
    end
end, { desc = "Toggle writing mode" })

-- explorer for when plugins arent installed
vim.keymap.set("n", "<leader>/", vim.cmd.Ex, { desc = "Indent right and reselect" })
