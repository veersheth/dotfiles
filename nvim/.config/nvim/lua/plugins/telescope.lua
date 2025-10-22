return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require("telescope").setup({
      defaults = {
        preview = { treesitter = false },
        color_devicons = true,
        sorting_strategy = "ascending",
        path_displays = { "smart" },
        layout_config = {
          -- height = 800,
          width = 600,
          prompt_position = "top",
          preview_cutoff = 40,
        }
      }
    })

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>fd', builtin.find_files)
    vim.keymap.set('n', '<leader>fs', builtin.live_grep)
    vim.keymap.set('n', '<leader>fb', builtin.buffers)
    vim.keymap.set('n', '<leader>fh', builtin.help_tags)
  end
}
