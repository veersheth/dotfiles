return {
  { -- theme: rosepine
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        styles = {
          transparency = true,
        }
      })
      vim.cmd("colorscheme rose-pine")
    end
  },
  { -- colorizer for coloring hex/rgb colors
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        names = false,
      },
    },
  }
}
