local vault = vim.fn.expand("~/sync/vault")
vim.fn.mkdir(vault, "p")
vim.fn.mkdir(vault .. "/999-templates", "p")

vim.pack.add({ "https://github.com/obsidian-nvim/obsidian.nvim" })
-- The plugin ships with a default frontmatter template; remove it so new notes
-- created from unresolved links stay empty unless the user inserts a template.
require("obsidian.config.default").note.template = nil
require("obsidian").setup({
  legacy_commands = false,
  workspaces = { { name = "vault", path = vault } },
  picker = { name = "telescope.nvim" },
  note = { template = vim.NIL },
  -- Keep parsing and alias lookup enabled, but don't generate frontmatter for
  -- newly created notes. Existing frontmatter is still preserved on save.
  frontmatter = { func = function() return {} end },
  note_id_func = require("obsidian.builtin").title_id,
  ui = { enable = false },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p")
    if path:sub(1, #vault + 1) == vault .. "/" then
      vim.keymap.set("n", "<CR>", "<cmd>Obsidian follow_link<cr>", {
        buffer = args.buf,
        desc = "follow vault link",
      })
    end
  end,
})

local function render_template(path)
  local lines = vim.fn.readfile(path)
  local basename = vim.fn.fnamemodify(path, ":t:r")
  local movie_title, poster = nil, ""

  if basename == "template-media-movie-show" then
    movie_title = vim.fn.input("Movie title? ")
    if movie_title == "" then
      return nil
    end

    local contents = table.concat(lines, "\n")
    local api_key = contents:match('local apiKey = "([^"]+)"')
    if api_key and vim.fn.executable("curl") == 1 then
      local url = "https://www.omdbapi.com/?t=" .. vim.uri_encode(movie_title) .. "&apikey=" .. api_key
      local ran, result = pcall(function()
        return vim.system({ "curl", "-fsS", "--max-time", "5", url }, { text = true }):wait()
      end)
      if ran and result.code == 0 then
        local ok, data = pcall(vim.json.decode, result.stdout)
        if ok and data.Poster and data.Poster ~= "N/A" then
          poster = data.Poster
        end
      end
    end
  end

  local date = os.date("%Y-%m-%d")
  local current_title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
  local daily_date = current_title:match("^(%d%d%d%d%-%d%d%-%d%d)%-daily$") or date
  local function format_date(pattern)
    local formats = {
      ["YYYY-MM-DD-HH:mm:ss"] = "%Y-%m-%d-%H:%M:%S",
      ["YYYY-MM-DD"] = "%Y-%m-%d",
      ["DD MMM YYYY"] = "%d %b %Y",
    }
    return os.date(formats[pattern] or "%Y-%m-%d")
  end

  local output, in_script = {}, false
  for _, line in ipairs(lines) do
    if line:match("<%%") and line:match("%*") then
      in_script = true
    elseif in_script and (line:match("%-%%>") or line:match("_%%>")) then
      in_script = false
    elseif not in_script then
      line = line:gsub('<%% tp%.date%.now%(["\'](.-)["\']%) %%>', format_date)
      line = line:gsub('<%% d%.format%(["\'](.-)["\']%) %%>', function(pattern)
        local fmt = pattern == "DD MMM YYYY" and "%d %b %Y" or "%Y-%m-%d"
        local year, month, day = daily_date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        return os.date(fmt, os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) }))
      end)
      if movie_title then
        line = line:gsub("<%% title %%>", movie_title):gsub("<%% poster %%>", poster)
      end
      output[#output + 1] = line
    end
  end
  return output
end

local function insert_template()
  local template_dir = vault .. "/999-templates"
  local files = vim.fn.globpath(template_dir, "*.md", false, true)
  if #files == 0 then
    vim.notify("No Markdown templates found in " .. template_dir, vim.log.levels.WARN)
    return
  end
  require("telescope.pickers").new({}, {
    prompt_title = "Insert template",
    finder = require("telescope.finders").new_table({
      results = files,
      entry_maker = function(path)
        return { value = path, display = vim.fn.fnamemodify(path, ":t:r"), ordinal = vim.fn.fnamemodify(path, ":t:r") }
      end,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local state = require("telescope.actions.state")
      local function choose()
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then return end
        local lines = render_template(entry.value)
        if not lines then return end
        local row = vim.api.nvim_win_get_cursor(0)[1]
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
      end
      map("i", "<CR>", choose)
      map("n", "<CR>", choose)
      return true
    end,
  }):find()
end
vim.keymap.set({ "n", "i" }, "<A-e>", function()
  if vim.fn.mode() == "i" then vim.cmd.stopinsert() end
  insert_template()
end, { desc = "insert vault template" })
