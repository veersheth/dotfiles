vim.pack.add({ 'https://github.com/vague-theme/vague.nvim' })

require('vague').setup({
  transparent = true,
  colors = {
    line = '#2f2f2f',
  },
})

vim.cmd.colorscheme('vague')
