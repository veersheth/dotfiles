-- -- -- -- -- -- -- -- -- -- -- --
-- oil
-- -- -- -- -- -- -- -- -- -- -- --

vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })

vim.keymap.set({ "n" }, "<leader>/", "<cmd>Oil<CR>", { desc = "open oil" })
vim.keymap.set({ "n" }, "<leader>?", "<cmd>Oil --preview<CR>", { desc = "preview oil" })

require "oil".setup({
  view_options = {
    show_hidden = true
  },
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    autosave_changes = true,
  },
  columns = {
    "icon",
    -- "permissions",
    -- "size",
    -- "mtime",
  },
  float = {
    max_width = 0.3,
    max_height = 0.6,
    border = "rounded",
  },
  skip_confirm_for_simple_edits = true,
  delete_to_trash = true,
  keymaps = { ["<Esc>"] = "actions.close" },
})

-- -- -- -- -- -- -- -- -- -- -- --
-- file tree
-- -- -- -- -- -- -- -- -- -- -- --

vim.pack.add({
  {
    src = 'https://github.com/nvim-neo-tree/neo-tree.nvim',
    version = vim.version.range('3')
  },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

require('neo-tree').setup({
  close_if_last_window = true,
  enable_git_status = false,

  default_component_configs = {
    icon = {
      folder_closed = "▸",
      folder_open   = "▾",
      folder_empty  = "▸",
      default       = "*",
      highlight     = "NeoTreeFileIcon",
    },
  },

  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      -- hide_gitignored = true,
    },
  },

  buffers = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
  }
})

vim.cmd([[
  highlight NeoTreeDiagnosticError guifg=#3a3a3a
  highlight NeoTreeDiagnosticWarn  guifg=#353535
  highlight NeoTreeDiagnosticInfo  guifg=#303030
  highlight NeoTreeDiagnosticHint  guifg=#2c2c2c
]])

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle left<cr>", { desc = "Toggle file tree" })

-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = vim.schedule_wrap(function()
--     vim.cmd("Neotree show")
--   end),
-- })
