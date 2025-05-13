return {
  "folke/zen-mode.nvim",
  opts = {
    on_open = function()
      vim.cmd("Gitsigns detach")  -- Disable gitsigns in Zen Mode
    end,
    on_close = function()
      vim.cmd("Gitsigns attach")  -- Re-enable gitsigns when exiting Zen Mode
    end,
  },
  keys = {
    { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen Mode" }
  }
}

