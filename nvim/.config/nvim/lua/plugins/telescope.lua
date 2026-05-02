vim.pack.add({ "https://github.com/aznhe21/actions-preview.nvim" })
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" })
vim.pack.add({ "https://github.com/nvim-telescope/telescope-ui-select.nvim" })
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })


local telescope = require "telescope" 

telescope.setup({
  defaults = {
    preview = { treesitter = false },
    color_devicons = true,
    sorting_strategy = "ascending",
    path_displays = { "smart" },
    layout_config = {
      -- height = 600,
      -- width = 600,
      prompt_position = "top",
      -- preview_cutoff = 40,
    },
  },
})


local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "find files" })
vim.keymap.set("n", "<leader>F", builtin.resume, { desc = "resume search" })
vim.keymap.set("n", "<leader>s", builtin.live_grep, { desc = "find strings" })
vim.keymap.set("n", "<leader>T", "<cmd>Telescope<cr>", { desc = "telescope itself" })
