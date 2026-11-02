-- vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
vim.pack.add({ "https://github.com/dhruvasagar/vim-table-mode" })
vim.g.table_mode_auto_align = 1
vim.g.table_mode_corner = "|"
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.cmd("TableModeEnable")
  end,
})
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

-- require("render-markdown").setup({
--   -- heading = { enabled = true, width = "block" },
--   bullet = { enabled = false },
--   latex = {
--     enabled = true,
--     converter = { "utftex", "latex2text" },
--     position = "center",
--   },
--   completions = { lsp = { enabled = true } },
-- })

vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "render markdown" })

vim.keymap.set("n", "<leader>mi", function()
  require("image").clear() 
end, { desc = "clear images" })
