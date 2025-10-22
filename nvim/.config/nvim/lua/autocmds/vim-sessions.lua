vim.api.nvim_create_user_command("SaveSession", function()
  vim.cmd("mksession! ./session.vim")
end, {})

vim.api.nvim_create_user_command("LoadSession", function()
  vim.cmd("source ./session.vim")
end, {})
