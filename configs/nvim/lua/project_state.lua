local M = {}

local state_path = vim.fn.stdpath('state') .. '/project-state.json'
local state = nil

local function read_state()
  if state then
    return state
  end

  local ok, lines = pcall(vim.fn.readfile, state_path)
  if not ok then
    state = { projects = {} }
    return state
  end

  local decode_ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  state = decode_ok and type(decoded) == 'table' and decoded or {}
  state.projects = type(state.projects) == 'table' and state.projects or {}
  return state
end

local function get_project_state()
  local projects = read_state().projects
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local git_marker = vim.fs.find('.git', { path = cwd, upward = true })[1]
  local key = git_marker and vim.fs.normalize(vim.fs.dirname(git_marker)) or cwd

  projects[key] = type(projects[key]) == 'table' and projects[key] or {}
  return projects[key]
end

function M.get(key, default)
  local value = get_project_state()[key]
  if value == nil then
    return default
  end
  return value
end

function M.set(key, value)
  get_project_state()[key] = value

  local encoded = vim.json.encode(read_state())
  vim.fn.mkdir(vim.fs.dirname(state_path), 'p')

  local ok, result = pcall(vim.fn.writefile, { encoded }, state_path)
  if not ok or result ~= 0 then
    vim.notify('Failed to write project state: ' .. tostring(result), vim.log.levels.WARN)
  end
end

return M
