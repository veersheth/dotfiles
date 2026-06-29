vim.pack.add({ "https://github.com/epwalsh/obsidian.nvim" })


vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

require("obsidian").setup({
  legacy_commands = false, 

  workspaces = {
    {
      name = "notes",
      path = "~/syncthing/notes",
    },
  },

  picker = {
    name = "telescope.nvim",
  },

  -- new_notes_location = "notes_subdir",
  -- notes_subdir = "notes", 

  attachments = { folder = "attachments", },

  templates = {
    enabled = true,
    folder = "999-templates", -- relative to vault root
    date_format = "YYYY-MM-DD",
    time_format = "HH:mm",
  },

  -- daily_notes = {
  --   enabled = true,
  --   folder = "dailies",
  --   date_format = "YYYY-MM-DD",
  -- },

  frontmatter = {
    enabled = true,
    sort = { "id", "aliases", "tags" },
  },

})
