vim.pack.add({ "https://github.com/epwalsh/obsidian.nvim" })


require("obsidian").setup({
  workspaces = {
    {
      name = "vault 3",
      path = "~/obsidian-vault-03"
    },
  },
})
