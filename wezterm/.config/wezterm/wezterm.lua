local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 16

config.window_background_opacity = 0.8

config.window_decorations = "NONE"

config.window_padding = {
	left = 20,
	right = 20,
	top = 20,
	bottom = 20,
}

config.colors = {
	foreground = "#dedede",
	background = "#000000", 

	cursor_bg = "#bb9af7", 
	cursor_fg = "#000000",
	cursor_border = "#bb9af7",

	selection_bg = "#444444",
	selection_fg = "#ffffff",

	ansi = {
		"#1a1b26", -- black
		"#ff9e64", -- pastel orange/red
		"#b9f27c", -- pastel green
		"#e0af68", -- pastel yellow
		"#7aa2f7", -- pastel blue
		"#bb9af7", -- pastel magenta
		"#7dcfff", -- pastel cyan
		"#dedede", -- white
	},
	brights = {
		"#414868", -- bright black (gray)
		"#f7768e", -- bright pastel pink/red
		"#9ece6a", -- bright pastel green
		"#ff9e64", -- bright pastel orange
		"#89ddff", -- bright pastel blue
		"#c0caf5", -- bright pastel lavender
		"#0db9d7", -- bright pastel aqua
		"#ffffff", -- bright white
	},

	tab_bar = {
		background = "#000000",
		active_tab = {
			bg_color = "#bb9af7",
			fg_color = "#000000",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#000000",
			fg_color = "#787c99",
		},
		inactive_tab_hover = {
			bg_color = "#1a1b26",
			fg_color = "#dedede",
		},
		new_tab = {
			bg_color = "#000000",
			fg_color = "#787c99",
		},
		new_tab_hover = {
			bg_color = "#000000",
			fg_color = "#bb9af7",
		},
	},
}

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

config.window_close_confirmation = "NeverPrompt"

config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

return config
