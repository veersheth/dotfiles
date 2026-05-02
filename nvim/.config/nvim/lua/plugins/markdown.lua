vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
vim.pack.add({ "https://github.com/3rd/image.nvim" })

require("image").setup({
  backend = "kitty",
  kitty_method = "normal",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = true,
      download_remote_images = true,
    },
  },
  max_width = 80,
  max_height = 20,
  max_width_window_percentage = 60,
  max_height_window_percentage = 40,
  window_overlap_clear_enabled = true,
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
})

require("render-markdown").setup({
  completions = { lsp = { enabled = true } },
})

vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "render markdown" })

vim.keymap.set("n", "<leader>mi", function()
  require("image").clear() 
end, { desc = "clear images" })
