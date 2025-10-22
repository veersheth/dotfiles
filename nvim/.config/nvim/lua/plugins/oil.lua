return {
  'stevearc/oil.nvim',
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    view_options = { show_hidden = true },
  },
  config = function()
    local oil = require("oil")
    oil.setup({
      lsp_file_methods = {
        enabled = true,
        timeout_ms = 1000,
        autosave_changes = true,
        skip_confirm_for_simple_edits = true,
        watch_for_changes = true,
      },
      columns = {
        -- "permissions",
        "icon",
      },
      float = {
        max_width = 0.7,
        max_height = 0.6,
        border = "rounded",
      }
    })

    -- oil in current window 
    vim.keymap.set({ "n", "x" }, "<leader>/", function()
      oil.open()
    end, { silent = true, desc = "Open Oil in current window" })
  end,
}
