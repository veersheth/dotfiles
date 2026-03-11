-- key mapping
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- theme & transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

vim.opt.number = true         -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.cursorline = false     -- Highlight current line
vim.opt.wrap = false          -- Don't wrap lines
vim.opt.scrolloff = 10        -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8     -- Keep 8 columns left/right of cursor
vim.o.winborder = "rounded"

-- indentation
vim.opt.tabstop = 2        -- Tab width
vim.opt.shiftwidth = 2     -- Indent width
vim.opt.softtabstop = 2    -- Soft tab stop
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart auto-indenting
vim.opt.autoindent = true  -- Copy indent from current line

-- search settings
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true  -- Case sensitive if uppercase in search
vim.opt.hlsearch = true   -- Highlight search results
vim.opt.incsearch = true  -- Show matches as you type

-- visual settings
vim.opt.signcolumn = "yes"                        -- Always show sign column
vim.opt.showmatch = true                          -- Highlight matching brackets
vim.opt.matchtime = 45                            -- How long to show matching bracket
vim.opt.cmdheight = 1                             -- Command line height
vim.opt.completeopt = "menuone,noinsert,noselect" -- Completion options
vim.opt.showmode = false                          -- Don't show mode in command line
vim.opt.pumheight = 10                            -- Popup menu height
vim.opt.pumblend = 10                             -- Popup menu transparency
vim.opt.winblend = 0                              -- Floating window transparency
vim.opt.conceallevel = 0                          -- Don't hide markup
vim.opt.concealcursor = ""                        -- Don't hide cursor line markup
vim.opt.synmaxcol = 300                           -- Syntax highlighting limit

-- file handling
vim.opt.backup = false                            -- Don't create backup files
vim.opt.writebackup = false                       -- Don't create backup before writing
vim.opt.swapfile = false                          -- Don't create swap files
vim.opt.undofile = true                           -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300                          -- Faster completion
vim.opt.timeoutlen = 500                          -- Key timeout duration
vim.opt.ttimeoutlen = 0                           -- Key code timeout
vim.opt.autoread = true                           -- Auto reload files changed outside vim

-- behavior settings
vim.opt.hidden = true                  -- Allow hidden buffers
vim.opt.errorbells = false             -- No error bells
vim.opt.backspace = "indent,eol,start" -- Better backspace behavior
vim.opt.autochdir = false              -- Don't auto change directory
vim.opt.modifiable = true              -- Allow buffer modifications
vim.opt.encoding = "UTF-8"             -- Set encoding

-- normal mode mappings
vim.keymap.set("n", "<leader>w", ":w", { desc = "write buffer" }) -- note that this doesn't have an enter
vim.keymap.set("n", "<leader>q", ":q", { desc = "quit buffer" })
vim.keymap.set("n", "<leader>W", ":wa", { desc = "write all buffers" })
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "" })

vim.keymap.set("v", "MN", ":norm ", { desc = "quick norm" })
vim.keymap.set("v", "id", "<Esc>ggVG", { desc = "select entire doc" })

-- system clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "copy to system clipboard" })
vim.keymap.set("n", "<leader>y", 'mzggVG"+y`z', { desc = "copy to system clipboard" })

-- center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "next and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "prev and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "page down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "page up and center" })

-- continuous indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "indent back" })
vim.keymap.set("v", ">", ">gv", { desc = "indent forw" })

-- buffer keymaps
vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { desc = "delete buffer" })
vim.keymap.set("n", "<leader>X", ":bdelete!<CR>", { desc = "delete buffer force" })
vim.keymap.set("n", "<leader>n", ":bnext<CR>", { desc = "next buffer" })
vim.keymap.set("n", "<leader>p", ":bprevious<CR>", { desc = "prev buffer" })
vim.keymap.set("n", "<leader>l", "<C-^>", { desc = "toggle last buffer" })
