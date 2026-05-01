vim.pack.add({ "christoomey/vim-tmux-navigator" })

vim.g.tmux_navigator_no_mappings = 1

vim.keymap.set('n', "<m-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set('n', "<m-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set('n', "<m-k>", "<cmd>TmuxNavigateUp<cr>")
vim.keymap.set('n', "<m-l>", "<cmd>TmuxNavigateRight<cr>")
vim.keymap.set('n', "<m-\\>", "<cmd>TmuxNavigatePrevious<cr>")
