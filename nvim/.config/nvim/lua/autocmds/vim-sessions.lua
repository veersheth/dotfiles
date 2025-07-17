vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.cmd("mksession! ~/.vim/session.vim")
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.filereadable("~/.vim/session.vim") == 1 then
      vim.cmd("source ~/.vim/session.vim")
    end
  end,
})
