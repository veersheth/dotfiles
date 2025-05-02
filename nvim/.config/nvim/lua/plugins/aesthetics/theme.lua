return {
  "vague2k/vague.nvim",
  config = function()
    require("vague").setup({ transparent = true })
    vim.cmd("colorscheme vague")
    vim.cmd(":hi statusline guibg=NONE")
  end

  -- "rose-pine/neovim",
  -- name = "rose-pine",
  -- config = function()
  --   require("rose-pine").setup({
  --     styles = {
  --       bold = true,
  --       italic = true,
  --       transparency = true,
  --     },
  --   })
  --
  --   vim.cmd("colorscheme rose-pine")
  -- end
}
