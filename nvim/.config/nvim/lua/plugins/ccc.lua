vim.pack.add({ "https://github.com/uga-rosa/ccc.nvim" })

local ccc = require("ccc")
      
ccc.setup({
  highlighter = {
    auto_enable = true,
    lsp = true, 
  },
  pickers = {
    ccc.picker.hex,
    ccc.picker.css_rgb,
    ccc.picker.css_hsl,
    ccc.picker.css_hwb,
    ccc.picker.css_lab,
  },
})

-- Keybindings
-- <leader>cp to pick a color
-- <leader>cv to convert the color under the cursor
vim.keymap.set("n", "<leader>cp", "<cmd>CccPick<cr>", { desc = "color picker" })
vim.keymap.set("n", "<leader>cv", "<cmd>CccConvert<cr>", { desc = "color converter" })
