vim.pack.add({ "https://github.com/3rd/image.nvim" })

require("image").setup({
  backend = "kitty",
  integrations = {
    markdown = {
      enabled = true,
      download_remote_images = true,
      filetypes = { "markdown", "vimwiki" },
    },
  },
  max_height_window_percentage = 50,
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
})
