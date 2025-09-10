return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", 
    },
    lazy = false,
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true,
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = false,
            default_component_configs = {
                indent = { padding = 1 },
                icon = { folder_closed = "", folder_open = "", folder_empty = "ﰊ" },
            },
            filesystem = {
                bind_to_cwd = true,
                hijack_netrw_behavior = "disabled", 
                follow_current_file = {
                    enabled = true, 
                    leave_dirs_open = false,
                },
            },
            window = {
                position = "right", -- always on the left
                width = 35,
            },
        })

        vim.keymap.set("n", "<leader>-", function()
            vim.cmd("Neotree toggle right")
        end, { desc = "Toggle file tree" })
    end,
}

