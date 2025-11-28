-- sesh management
local function save_session()
  local stdpath_cache = vim.fn.stdpath('cache')
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  local cache_dir = stdpath_cache .. '/sessions'
  local session_file = cache_dir .. '/' .. project .. '.vim'
  vim.fn.mkdir(cache_dir, 'p')
  vim.cmd('mksession! ' .. session_file)
end

local function load_session()
  local stdpath_cache = vim.fn.stdpath('cache')
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  local session_file = stdpath_cache .. '/sessions/' .. project .. '.vim'
  if vim.fn.filereadable(session_file) == 1 then
    vim.cmd('source ' .. session_file)
    vim.notify('Session loaded', vim.log.levels.INFO)
  else
    vim.notify('Session file not found', vim.log.levels.WARN)
  end
end

vim.keymap.set('n', '<leader>PS', save_session, { desc = 'Save project session', silent = true })
vim.keymap.set('n', '<leader>P', load_session, { desc = 'Load project session', silent = true })

-- auto-save session on file write
vim.api.nvim_create_autocmd('BufWritePost', {
  callback = save_session,
  desc = 'Auto-save session on file save',
})


