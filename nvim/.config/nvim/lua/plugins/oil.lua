return {
  'stevearc/oil.nvim',
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    view_options = { show_hidden = true },
  },
  config = function()
    local oil = require("oil")
    oil.setup({})

    -- oil in current window
    vim.keymap.set({ "n", "x" }, "<leader>/", function()
      oil.open()
    end, { silent = true, desc = "Open Oil in current window" })
  end,
}

