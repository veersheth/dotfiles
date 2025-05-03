return {
    {
        "epwalsh/obsidian.nvim",
        version = "*",
        lazy = true,
        ft = "markdown",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = {
            workspaces = {
                {
                    name = "vaul 0",
                    path = "~/vault-0/",
                },
            },
        },
    }
    , {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = false,
    opts = {},
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }
}
}
