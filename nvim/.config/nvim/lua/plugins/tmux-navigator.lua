return {
  "christoomey/vim-tmux-navigator",
  lazy = false,  -- load immediately so keymaps always work
  init = function()
    -- disable default Ctrl-h/j/k/l mappings
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
      { "<m-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<m-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<m-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<m-l>", "<cmd>TmuxNavigateRight<cr>" },
      { "<m-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
}

