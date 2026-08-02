vim.pack.add({ "https://github.com/obsidian-nvim/obsidian.nvim" })

require("obsidian").setup {
  legacy_commands = false,

  picker = {
    name = "telescope.nvim",
  },

  workspaces = {
    {
      name = "notes",
      path = "~/syncthing/notes",
    },
  },

  attachments = {
    folder = "999-attachments",
    img_text_func = require("obsidian.builtin").img_text_func,
    img_name_func = function()
      return string.format("Pasted image %s", os.date "%Y%m%d%H%M%S")
    end,
    confirm_img_paste = true, -- TODO: move to paste module, paste.confirm
  },

  -- new_notes_location = "current_dir",

  note_id_func = require("obsidian.builtin").title_id,

  ui = {
    external_link_icon = { char = "" },
  },
}
