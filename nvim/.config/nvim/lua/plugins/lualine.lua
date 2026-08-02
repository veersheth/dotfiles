vim.pack.add({
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/nvim-lualine/lualine.nvim'
})

require("lualine").setup({
  options = {
    theme = 'auto',
    icons_enabled = true,
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    lualine_x = {
      {
        function()
          return writing_mode_state[vim.api.nvim_get_current_buf()] and "󰴒  writing" or ""
        end,
      },
      "filetype",
    },
  },
})
