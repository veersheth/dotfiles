-- key mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "


-- for when plugins arent installed
vim.keymap.set("n", "<leader>/", vim.cmd.Ex, { desc = "Indent right and reselect" })

-- theme & transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- basic settings
vim.opt.number = true         -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.cursorline = true     -- Highlight current line
vim.opt.wrap = false          -- Don't wrap lines
vim.opt.scrolloff = 10        -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8     -- Keep 8 columns left/right of cursor

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
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "unhighlight searches" })

-- yank to clipboard
vim.keymap.set("v", "Y", '"+y', { desc = "Copy to system" })

-- select document vid
vim.keymap.set("v", "id", "<Esc>ggVG", { desc = "Entire document" })

-- center screen when jumping
vim.keymap.set("n", "n", "nzzzv", {})
vim.keymap.set("n", "N", "Nzzzv", {})
vim.keymap.set("n", "<C-d>", "<C-d>zz", {})
vim.keymap.set("n", "<C-u>", "<C-u>zz", {})

-- buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

-- better window navigation
vim.keymap.set("n", "<M-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<M-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<M-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<M-l>", "<C-w>l", { desc = "Move to right window" })

-- splitting & resizing
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- move lines up/down
vim.keymap.set("v", "<C-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<C-j>", ":m .+1<CR>==", { desc = "Move line down" })

-- better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- session management

-- Save session in .nvim/session.vim under the project root
vim.keymap.set('n', '<leader>ss', function()
  local session_path = vim.fn.getcwd() .. '/.nvim/session.vim'
  vim.fn.mkdir(vim.fn.getcwd() .. '/.nvim', 'p') -- Ensure the .nvim dir exists
  vim.cmd('mksession! ' .. session_path)
end, { desc = 'Save session in project dir', silent = true })

-- Load session from .nvim/session.vim
vim.keymap.set('n', '<leader>sl', function()
  local session_path = vim.fn.getcwd() .. '/.nvim/session.vim'
  if vim.fn.filereadable(session_path) == 1 then
    vim.cmd('source ' .. session_path)
  else
    print('Session file not found in project directory.')
  end
end, { desc = 'Load session from project dir', silent = true })

