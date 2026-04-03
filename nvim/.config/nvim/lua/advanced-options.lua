-- typst pdf autocompile

vim.keymap.set("n", "<leader>tp", function()
	local file = vim.fn.expand("%:p")
	local pdf = vim.fn.expand("%:r") .. ".pdf"
	local cmd = string.format("typst watch %s & sioyek %s", file, pdf)
	vim.fn.jobstart({ "bash", "-c", cmd }, { detach = true })
end, { desc = "typst preview" })

-- LaTeX zathura preview
vim.keymap.set("n", "<leader>tl", function()
	local file = vim.fn.expand("%:p")
	local pdf = vim.fn.expand("%:r") .. ".pdf"

	-- -pdf: Generate PDF
	-- -pvc: Preview Continuous (watches for changes)
	-- -interaction=nonstopmode: Don't stop on errors
	local cmd = string.format("latexmk -pdf -pvc -interaction=nonstopmode %s & sioyek %s", file, pdf)

	vim.fn.jobstart({ "bash", "-c", cmd }, { detach = true })
end, { desc = "latex preview (auto-compile)" })

-- writing mode
local writing_mode = false

vim.keymap.set("n", "<leader>tw", function()
	writing_mode = not writing_mode

	if writing_mode then
		vim.opt_local.wrapmargin = 10
		vim.opt_local.formatoptions:append("t")
		vim.opt_local.linebreak = true
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
		-- fake margins
		vim.opt_local.signcolumn = "yes:1"
		vim.notify("Writing mode enabled", vim.log.levels.WARN)
	else
		vim.opt_local.wrapmargin = 0
		vim.opt_local.formatoptions:remove("t")
		vim.opt_local.linebreak = false
		vim.opt_local.wrap = false
		vim.opt_local.spell = false
		-- reset margins
		vim.opt_local.foldcolumn = "0"
		vim.opt_local.signcolumn = "yes"
		vim.notify("Writing mode disabled", vim.log.levels.WARN)
	end
end, { desc = "toggle writing mode" })

-- vim.keymap.set("n", "<leader><leader>", "mbggVGgw`b:w<CR>")
vim.keymap.set("n", "<leader><leader>", "mnvipgw`n", { desc = "wrap paragraph" })

-- explorer for when plugins arent installed
vim.keymap.set("n", "<leader>/", vim.cmd.Ex, { desc = "netrw" })

-- surround
vim.keymap.set("v", "<leader>S", function()
	local input = vim.fn.input("Surround with ")
	if input == "" then
		return
	end

	local pairs = {
		["("] = { "(", ")" },
		["["] = { "[", "]" },
		["{"] = { "{", "}" },
		["<"] = { "<", ">" },
	}

	local open = pairs[input] and pairs[input][1] or input
	local close = pairs[input] and pairs[input][2] or input

	local keys = vim.api.nvim_replace_termcodes("c" .. open .. '<C-r>"' .. close .. "<Esc>", true, false, true)
	vim.api.nvim_feedkeys(keys, "m", false)
end, { desc = "Surround" })
