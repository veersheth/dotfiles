vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.background = "light"
vim.opt.cursorline = true

vim.opt.swapfile = false
vim.opt.scrolloff = 10

-- copy visual selection to WSL clipboard
vim.keymap.set("v", "<leader>cc", ":w !clip.exe<CR>", { desc = "Copy to clipboard" })
vim.keymap.set("v", "Y", "\"+y", { desc = "Copy to clipboard" })

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Unhighlight search params" })
vim.wo.number = true
vim.wo.relativenumber = true

vim.api.nvim_set_keymap("n", "<leader>s", ":w<CR>", {
	noremap = true,
	silent = true,
	desc = "Save",
})

vim.api.nvim_set_keymap("n", "<leader>F", ":lua vim.lsp.buf.format()<CR>", {
	noremap = true,
	silent = true,
	desc = "Format Document",
})

-- Highlight text after yank for a brief period
vim.api.nvim_exec(
	[[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank({timeout=300})
  augroup end
]],
	false
)

-- Vertical scroll and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)

vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)

-- Resize vim splits with arrow keys
vim.keymap.set("n", "<Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", opts)

-- Buffer nav
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bn", "<cmd> enew <CR>", { desc = "New buffer" })
vim.keymap.set("n", "<leader>bw", ":bdelete<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>BW", ":bdelete!<CR>", { desc = "Close buffer FORCE" })
