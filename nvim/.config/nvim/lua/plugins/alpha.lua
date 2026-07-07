vim.pack.add({ "https://github.com/goolord/alpha-nvim" })
local dashboard = require('alpha.themes.dashboard')

dashboard.section.header.val = {
  [[]],
  [[]],
  [[]],
  [[]],
  [[]],
  [[]],
  [[]],
  [[               ⠄⠄⠄⠄⠄⣠⣤⣤⣤⣄⡀⠄⠄⠄⢀⣤⣶⣶⣤⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄               ]],
  [[               ⠄⠄⠄⢠⣾⣿⣿⠿⢿⣿⣷⣀⣀⣠⣿⣿⣿⠿⣿⣿⣦⠄⠄⠄⠄⠄⠄⠄⠄⠄               ]],
  [[               ⠄⠄⠄⠘⣿⣿⣿⣤⣼⣿⣿⣿⣿⣿⣿⣿⣧⣤⣿⣿⣿⢀⡀⢰⣦⢀⣠⡀⠄⠄               ]],
  [[               ⠄⠄⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣾⣿⢸⣿⢸⣿⡇⣶⡄               ]],
  [[               ⠄⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⢸⣿⢸⣿⡇⣿⡇               ]],
  [[               ⠄⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⢸⣿⢸⣿⡇⣿⡇               ]],
  [[               ⠄⣿⣿⣿⡿⠫⠭⠶⢦⣭⣭⣭⣭⣭⣭⣭⣭⢱⣬⡙⢣⣿⣿⣿⣿⣿⣿⣧⣿⠃               ]],
  [[               ⣀⢸⣿⣿⣷⣬⣝⣛⣒⣒⣒⣒⣒⣒⡒⠢⠭⠤⢹⣷⣾⣿⣿⣿⣿⣿⣿⣿⣿⠄               ]],
  [[               ⣿⣦⡻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄               ]],
  [[               ⣿⣿⣿⣶⣍⡛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢟⣓⣘⠿⣿⣿⣿⣿⡿⠿⠿⠋⠄               ]],
  [[               ⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⢏⣶⣶⣶⣶⣾⣿⠄⠄⠄               ]],
  [[]],
  [[]],
  [[]],
}


-- Dynamic section: evaluated each time alpha redraws
dashboard.section.buttons.val = function()
  local buttons = {}
  local keys = { "1", "2", "3", "4", "5" }
  local count = 0

  for _, path in ipairs(vim.v.oldfiles) do
    if count >= 5 then break end
    if vim.fn.filereadable(path) == 1 then
      count = count + 1
      local short = vim.fn.fnamemodify(path, ":~:.")
      local display = #short > 50 and ("…" .. short:sub(-49)) or short
      table.insert(buttons, dashboard.button(keys[count], "  " .. display, ":e " .. vim.fn.fnameescape(path) .. "<CR>"))
    end
  end

  -- Separator
  table.insert(buttons, { type = "text", val = "", opts = { hl = "Comment", position = "center" } })

  table.insert(buttons, dashboard.button("f", "find files", ":Telescope find_files<CR>"))
  table.insert(buttons, dashboard.button("x", "clean packages", function() pack_clean() end))
  table.insert(buttons, dashboard.button("q", "quit", ":qa<CR>"))

  return buttons
end

-- Tell alpha the buttons section is dynamic
dashboard.section.buttons.type = "group"

require('alpha').setup(dashboard.opts)
