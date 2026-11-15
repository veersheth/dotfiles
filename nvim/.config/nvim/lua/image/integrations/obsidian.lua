local document = require("image/utils/document")

local vault = vim.fn.expand("~/sync/vault")
local image_extensions = { png = true, jpg = true, jpeg = true, gif = true, webp = true, avif = true, svg = true }

local function resolve_image_path(document_path, image_path, fallback)
  local candidates = {
    fallback(document_path, image_path),
    vault .. "/" .. image_path,
    vault .. "/999-attachments/" .. image_path,
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return candidates[1]
end

return document.create_document_integration({
  name = "obsidian",
  default_options = { filetypes = { "markdown" }, resolve_image_path = resolve_image_path },
  query_buffer_images = function(buf)
    local matches = {}
    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      for start_col, target in line:gmatch("()!%[%[([^%]]+)%]%]") do
        local path = target:match("^([^|]+)")
        local extension = path and path:lower():match("%.([^.]+)$")
        if image_extensions[extension] then
          matches[#matches + 1] = {
            url = path,
            range = {
              start_row = row - 1,
              start_col = start_col - 1,
              end_row = row - 1,
              end_col = start_col + #target + 4,
            },
          }
        end
      end
    end
    return matches
  end,
})
