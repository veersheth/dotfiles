return {
  'nvim-mini/mini.tabline',
  version = false,
  config = function()
    require "mini.tabline".setup({
      -- Whether to show file icons (requires 'mini.icons')
      show_icons = true,

      -- Function which formats the tab label
      -- By default surrounds with space and possibly prepends with icon
      format = nil,

      -- Where to show tabpage section in case of multiple vim tabpages.
      -- One of 'left', 'right', 'none'.
      tabpage_section = 'left',
    })
  end
}

-- return {
--   "akinsho/bufferline.nvim",
--   version = "*",
--   dependencies = "nvim-tree/nvim-web-devicons",
--   config = function()
--     vim.opt.termguicolors = true
--
--     require("bufferline").setup {
--       options = {
--         mode = "buffers", -- set to "tabs" to only show tabpages instead
--         numbers = "none",
--         color_icons = false,
--         separator_style = "none",
--         indicator = { style = "none", },
--         modified_icon = "●",
--         show_buffer_close_icons = false,
--         always_show_bufferline = true,
--       },
--       highlights = {
--         buffer_selected       = { bg = "#404040" },
--         background            = { bg = "none" },
--
--         -- required to color the whole active tab
--         fill                  = { bg = "none" },
--         tab_selected          = { bg = "#404040" },
--         tab                   = { bg = "none" },
--
--         close_button_selected = { bg = "#404040" },
--         close_button_visible  = { bg = "none" },
--         close_button          = { bg = "none" },
--
--         modified_selected     = { bg = "#404040" },
--         modified_visible      = { bg = "none" },
--         modified              = { bg = "none" },
--
--         separator_selected    = { bg = "#404040", fg = "#404040" },
--         separator_visible     = { bg = "none", fg = "none" },
--         separator             = { bg = "none", fg = "none" },
--       }
--
--     }
--   end,
-- }
