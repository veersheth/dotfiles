vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
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

local image_ok, image_err = pcall(require("image").setup, {
  backend = "sixel",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
    },
    obsidian = { enabled = true },
  },
  max_width = 80,
  max_height = 20,
  max_width_window_percentage = 60,
  max_height_window_percentage = 40,
  window_overlap_clear_enabled = true,
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
})
if not image_ok then
  vim.notify("image.nvim unavailable: " .. tostring(image_err), vim.log.levels.WARN)
end

require("render-markdown").setup({
  bullet = { enabled = false },
  latex = {
    enabled = true,
    converter = { "utftex", "latex2text" },
    position = "center",
  },
  completions = { lsp = { enabled = true } },
})

vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "render markdown" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    local src = require("render-markdown.core.preview").get(args.buf)
    if not src then return end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      -- The preview has no file path and opens before its filetype is set.
      -- Give it the source directory, then let image.nvim scan its contents.
      vim.api.nvim_buf_set_name(args.buf, vim.api.nvim_buf_get_name(src) .. ".preview")
      vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = args.buf })
    end)
  end,
})

vim.keymap.set("n", "<leader>mp", "<cmd>RenderMarkdown preview<cr>", { desc = "preview markdown" })

vim.keymap.set("n", "<leader>mi", function()
  require("image").clear() 
end, { desc = "clear images" })
