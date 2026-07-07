-- typst preview
--
vim.keymap.set("n", "<leader>tp", function()
	local file = vim.fn.expand("%:p")
	local pdf = vim.fn.expand("%:r") .. ".pdf"
	local cmd = string.format("typst watch %s & sioyek %s", file, pdf)
	vim.fn.jobstart({ "bash", "-c", cmd }, { detach = true })
end, { desc = "typst preview" })

-- writing mode
--
-- State is buffer-local (keyed by bufnr) so each buffer remembers its own
-- on/off status independently -- this matters once it's auto-enabled per
-- filetype, since you don't want toggling it off in one markdown buffer to
-- affect another, or get clobbered when autocmds re-fire.
local writing_mode_state = {}

local function set_writing_mode(bufnr, enabled)
	writing_mode_state[bufnr] = enabled
	if enabled then
		vim.opt_local.wrapmargin = 10
		vim.opt_local.formatoptions:append("t")
		vim.opt_local.linebreak = true
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
		-- fake margins
		vim.opt_local.signcolumn = "yes:1"
	else
		vim.opt_local.wrapmargin = 0
		vim.opt_local.formatoptions:remove("t")
		vim.opt_local.linebreak = false
		vim.opt_local.wrap = false
		vim.opt_local.spell = false
		-- reset margins
		vim.opt_local.foldcolumn = "0"
		vim.opt_local.signcolumn = "yes"
	end
end

vim.keymap.set("n", "<leader>tw", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local enabled = not writing_mode_state[bufnr]
	set_writing_mode(bufnr, enabled)
	if enabled then
		vim.notify("Writing mode enabled", vim.log.levels.WARN)
	else
		vim.notify("Writing mode disabled", vim.log.levels.WARN)
	end
end, { desc = "toggle writing mode" })

-- Auto-enable writing mode for typst and markdown files.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "typst", "markdown" },
	callback = function(ev)
		set_writing_mode(ev.buf, true)
	end,
})

local function pack_clean()
  local active_plugins = {}
  local unused_plugins = {}
  for _, plugin in ipairs(vim.pack.get()) do
    active_plugins[plugin.spec.name] = plugin.active
  end
  for _, plugin in ipairs(vim.pack.get()) do
    if not active_plugins[plugin.spec.name] then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end
  if #unused_plugins == 0 then
    print("No unused plugins.")
    return
  end
  local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
  if choice == 1 then
    vim.pack.del(unused_plugins)
  end
end
 
vim.keymap.set("n", "<leader>PC", function() pack_clean() end, { desc = "pack clean" })
