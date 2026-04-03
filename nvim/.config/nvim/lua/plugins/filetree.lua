return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>-", "<cmd>Neotree toggle<cr>", desc = "Neo-tree" },
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = {
        enabled = true,
      },
      use_libuv_file_watcher = true,
    },
    window = {
      width = 30,
      mappings = {
        ["<space>"] = "none", -- Disable space to avoid conflict with leader
      },
    },
    default_component_configs = {
      indent = {
        with_expanders = true, -- Adds triangles to folders
        expander_collapsed = "",
        expander_expanded = "",
      },
    },
  },
}
