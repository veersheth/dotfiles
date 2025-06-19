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
                    name = "vault-0", -- Corrected 'vaul 0' to 'vault 0'
                    path = "~/notes/",
                },
            },
            -- Add the templates configuration here
            templates = {
                folder = "999 Templates", -- Relative path from your vault root
                -- You can also specify an exact file name for a default template if you have one
                -- default_template = "Daily Note.md",
            },
        },
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        enabled = false,
        opts = {},
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }
    }
}
