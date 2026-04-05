local M = {}

local function get_wiki_link_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local search_start = 1

  while true do
    local start_col, end_col, body = line:find("%[%[([^%]]+)%]%]", search_start)
    if not start_col then
      return nil
    end

    if col >= start_col and col <= end_col then
      return body
    end

    search_start = end_col + 1
  end
end

local function wiki_link_to_path(link)
  local target = vim.trim(link)

  target = target:gsub("|.*$", "")
  target = target:gsub("#.*$", "")
  target = vim.trim(target)

  if target == "" then
    return nil
  end

  if not target:match("%.[^/\\]+$") then
    target = target .. ".md"
  end

  local current_dir = vim.fn.expand("%:p:h")
  return vim.fs.normalize(current_dir .. "/" .. target)
end

function M.open_or_create_wiki_link()
  local link = get_wiki_link_at_cursor()
  if not link then
    return false
  end

  local path = wiki_link_to_path(link)
  if not path then
    return false
  end

  local dir = vim.fs.dirname(path)
  if dir and vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  if vim.fn.filereadable(path) == 0 then
    local fd = assert(vim.uv.fs_open(path, "w", 420))
    vim.uv.fs_close(fd)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  return true
end

return M
