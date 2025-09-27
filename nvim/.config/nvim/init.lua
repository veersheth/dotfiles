require("options")
require("advanced-options")
require("autocmds.low-level-autocmds")
require("autocmds.vim-sessions")

-- if nvim is called on a directory, scope session to it
local function find_start_dir()
  -- skip the 'nvim' command itself
  for i = 2, #vim.v.argv do
    local arg = vim.v.argv[i]

    if not arg:match("^%-") and vim.fn.isdirectory(arg) == 1 then
      print("cd-ed to directory: ", arg)
      return arg
    end
  end

  return nil
end

local foldertogo = find_start_dir()
if foldertogo then
  local group = vim.api.nvim_create_augroup("FolderToGo", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      vim.cmd.cd(foldertogo)
    end,
  })
end

require("lazy-config")
