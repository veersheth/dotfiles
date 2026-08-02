-- key mapping
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true -- highlight current line
vim.opt.wrap = false
vim.opt.scrolloff = 12
vim.o.winborder = "rounded"

-- indentation
vim.opt.tabstop = 2        -- tab width
vim.opt.shiftwidth = 2     -- indent width
vim.opt.softtabstop = 2    -- soft tab stop
vim.opt.expandtab = true   -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indenting
vim.opt.autoindent = true  -- copy indent from current line

-- search settings
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true  -- Case sensitive if uppercase in search
vim.opt.hlsearch = true   -- Highlight search results
vim.opt.incsearch = true  -- Show matches as you type

-- visual settings
vim.opt.signcolumn = "yes"
vim.opt.showmatch = true

vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true

-- normal mode mappings
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "" })
vim.keymap.set("v", "id", "<Esc>ggVG", { desc = "select entire doc" })
vim.keymap.set("n", "<leader>R", vim.cmd.restart, { desc = "restart nvim" })

-- system clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "copy to system clipboard" })
vim.keymap.set("n", "<leader>y", 'mzggVG"+y`z', { desc = "copy to system clipboard" })

-- center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "next" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "prev" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "page down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "page up" })

-- continuous indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "indent back" })
vim.keymap.set("v", ">", ">gv", { desc = "indent forw" })

-- buffer keymaps
vim.keymap.set("n", "<leader>l", "<C-^>", { desc = "toggle last buffer" })

