vim.pack.add({ 'https://github.com/vague-theme/vague.nvim' })

require('vague').setup({
  transparent = true,
  colors = {
    line = '#0f0f0f',
  },
})

vim.cmd.colorscheme('vague')
