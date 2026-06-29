vim.pack.add({ "https://github.com/akinsho/bufferline.nvim" })
require('bufferline').setup({
  options = {
    offsets = {
      {
        filetype = "neo-tree",
        text = "",
        separator = false,
      },
    },
    indicator = { style = 'none' },
    buffer_close_icon = '',
    modified_icon = '',
    close_icon = '',
    left_trunc_marker = '',
    right_trunc_marker = '',
    show_buffer_close_icons = false,
    show_close_icon = false,
    show_tab_indicators = false,
    separator_style = { '', '' },
    always_show_bufferline = true,
  },
  highlights = {
    buffer_selected = { bg = '#202020', fg = '#ffffff', bold = false, italic = false },
    buffer_visible = { bg = 'none', fg = '#888888' },
    background = { bg = 'none', fg = '#888888' },
    fill = { bg = 'none' },
    separator = { bg = 'none', fg = 'none' },
    separator_selected = { bg = '#ffffff', fg = 'none' },
    separator_visible = { bg = 'none', fg = 'none' },
  },
})

vim.keymap.set('n', '<leader>n', '<cmd>BufferLineCycleNext<CR>', { desc = 'next buffer' })
vim.keymap.set('n', '<leader>p', '<cmd>BufferLineCyclePrev<CR>', { desc = 'prev buffer' })

vim.keymap.set('n', '<leader>w', function()
  if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then
    vim.cmd('bdelete')
  else
    local current = vim.fn.bufnr('%')
    require "oil".open()
    vim.cmd('bdelete ' .. current)
  end
end, { desc = 'close current buffer' })

for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, '<cmd>BufferLineGoToBuffer ' .. i .. '<CR>', { desc = 'buffer ' .. i })
end
vim.keymap.set('n', '<leader>0', '<cmd>BufferLineGoToBuffer 10<CR>', { desc = 'buffer 10' })
