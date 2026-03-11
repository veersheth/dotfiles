require("options")
require("advanced-options")
require("autocmds.low-level-autocmds")
require("autocmds.vim-sessions")
require("autocmds.autosave")

local function find_start_dir()
  -- iterate over command-line args
  for _, arg in ipairs(vim.v.argv) do
    -- skip flags like -n, -u, etc.
    if not arg:match("^%-") and vim.fn.isdirectory(arg) == 1 then
      print("cd-ed to directory: " .. arg)
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
