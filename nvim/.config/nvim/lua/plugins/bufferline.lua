return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    vim.opt.termguicolors = true

    require("bufferline").setup {
      options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        numbers = "none",
        color_icons = false,
        separator_style = "none",
        indicator = { style = "none", },
        modified_icon = "●",
        show_buffer_close_icons = false,
        always_show_bufferline = true,
      },
      highlights = {
        buffer_selected       = { bg = "#303030" },
        background            = { bg = "none" },

        -- required to color the whole active tab
        fill                  = { bg = "none" },
        tab_selected          = { bg = "#303030" },
        tab                   = { bg = "none" },

        close_button_selected = { bg = "#303030" },
        close_button_visible  = { bg = "none" },
        close_button          = { bg = "none" },

        modified_selected     = { bg = "#303030" },
        modified_visible      = { bg = "none" },
        modified              = { bg = "none" },

        separator_selected    = { bg = "#303030", fg = "#303030" },
        separator_visible     = { bg = "none", fg = "none" },
        separator             = { bg = "none", fg = "none" },
      }

    }
  end,
}
