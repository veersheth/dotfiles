return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- Adds file icons
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree", -- Lazy load when Neo-tree is used
	keys = {
		{ "<leader>-", ":Neotree right<CR>", desc = "Open filetree" },
		{ "<leader>_", ":Neotree toggle right<CR>", desc = "Toggle filetree" },
		{ "<leader>e", ":Neotree float<CR>", desc = "Toggle floating neotree" },
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = true, -- Close when it's the last window
			popup_border_style = "rounded", -- Nice rounded popup
			enable_git_status = true, -- Show Git status
			enable_diagnostics = true, -- Show LSP diagnostics
			default_component_configs = {
				indent = {
					with_markers = true,
					with_expanders = true, -- Show expand/collapse indicators
				},
				icon = {
					folder_closed = " ", -- Custom folder icon
					folder_open = " ",
					folder_empty = " ",
				},
				git_status = {
					symbols = {
						added = " ", -- Git added
						modified = " ", -- Git modified
						deleted = " ", -- Git deleted
						renamed = "➜ ",
						untracked = "★",
					},
				},
			},
			filesystem = {
				follow_current_file = {
					enabled = true, -- Track active file
				},
				hijack_netrw_behavior = "open_current",
				use_libuv_file_watcher = true, -- Better performance
			},
			window = {
				width = 30,
				mappings = {
					["<space>"] = "noop", -- Disable default space key behavior
				},
			},
			-- event_handlers = {
			-- 	{
			-- 		event = "file_opened",
			-- 		handler = function() require("neo-tree.command").execute({ action = "close" }) end,
			-- 	},
			-- },
		})

		-- Improve colors for a more elegant look
		-- vim.cmd([[
		-- 	hi NeoTreeNormal guibg=#181818 guifg=#cdd6f4
		-- 	hi NeoTreeNormalNC guibg=#181818 guifg=#cdd6f4
		-- 	hi NeoTreeGitAdded guifg=#a6e3a1
		-- 	hi NeoTreeGitModified guifg=#fab387
		-- 	hi NeoTreeGitDeleted guifg=#f38ba8
		-- ]])
	end,
}

