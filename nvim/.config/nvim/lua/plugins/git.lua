vim.pack.add({ "lewis6991/gitsigns.nvim" })

local gitsigns = require("gitsigns")

gitsigns.setup({
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 0,
  },
  current_line_blame_formatter = " --> <author>, <author_time:%R> - <summary>",
})

vim.keymap.set("n", "<leader>gb", function()
  gitsigns.toggle_current_line_blame()
end, { desc = "toggle git line blame" })



vim.keymap.set("n", "<leader>gs", "<cmd>Telescope git_b_commits<cr>", { desc = "commits affecting this buffer" })
