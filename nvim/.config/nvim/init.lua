require("options")
require("autocmds.low-level-autocmds")
require("autocmds.vim-sessions")
require("lazy-config")

-- if nvim is called on a directory, scope session to it
local function find_start_dir()
  for _, arg in ipairs(vim.v.argv) do
    if not arg:match("^%-") and vim.fn.isdirectory(arg) == 1 then
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

