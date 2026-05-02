--
-- cd to a directory, if passed
local function find_start_dir()
  for _, arg in ipairs(vim.v.argv) do
    if not arg:match("^%-") and vim.fn.isdirectory(arg) == 1 then
      print("cd-ed to directory: " .. arg)
      return arg
    end
  end
  return nil
end

local foldertogo = find_start_dir()

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if foldertogo then
      vim.cmd.cd(foldertogo)
    end
    if vim.fn.argc() == 0 then
      require("telescope.builtin").oldfiles()
    end
  end,
})

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

require("options")
require("advanced-options")

require("autocmds.basic")
require("autocmds.autosave")

require("plugins.oil")
require("plugins.telescope")
require("plugins.tmux-navigator")
require("plugins.lsp")
require("plugins.treesitter")
require("plugins.ccc")
require("plugins.luasnip")
require("plugins.git")
require("plugins.markdown")
require("plugins.obsidian")
-- require("plugins.alpha")

require("theme")

