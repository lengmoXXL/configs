local M = {}

local next_id = 0
local last_id = nil

local function sync_title(terminal)
  local title = vim.trim(vim.b[terminal.buf].config_terminal_manual_title or '')
  if title == '' then
    title = vim.fn.fnamemodify(vim.api.nvim_get_chan_info(vim.bo[terminal.buf].channel).argv[1], ':t')
  end

  title = vim.b[terminal.buf].config_terminal_id .. ' ' .. title
  terminal:set_title(title, 'left')
  return title
end

local function hide_visible_terminals()
  local hidden = false
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal:valid() then
      terminal:hide()
      hidden = true
    end
  end
  return hidden
end

local function focus_terminal(terminal)
  hide_visible_terminals()
  last_id = vim.b[terminal.buf].config_terminal_id
  sync_title(terminal)
  terminal:show():focus()
end

local function current_terminal()
  local current_buf = vim.api.nvim_get_current_buf()
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal.buf == current_buf then
      return terminal
    end
  end
end

function M.create()
  next_id = next_id + 1
  local id = next_id

  hide_visible_terminals()

  local terminal = Snacks.terminal.open(nil, {
    count = id,
    auto_close = false,
    win = {
      position = 'float',
      width = 0.99,
      height = 0.65,
      row = 0.30,
      border = 'single',
      title_pos = 'left',
    },
  })

  vim.b[terminal.buf].config_terminal_id = id
  last_id = id
  sync_title(terminal)
end

function M.toggle()
  if hide_visible_terminals() then
    return
  end

  local terminals = Snacks.terminal.list()
  for _, terminal in ipairs(terminals) do
    if vim.b[terminal.buf].config_terminal_id == last_id then
      focus_terminal(terminal)
      return
    end
  end

  if terminals[1] then
    focus_terminal(terminals[1])
    return
  end

  M.create()
end

function M.close_current()
  local terminal = current_terminal()
  if not terminal then
    Snacks.notify.warn('No terminal to close')
    return
  end

  terminal:close()
end

function M.rename_current()
  local terminal = current_terminal()
  if not terminal then
    Snacks.notify.warn('No terminal to rename')
    return
  end

  vim.ui.input({
    prompt = 'Terminal name: ',
    default = vim.b[terminal.buf].config_terminal_manual_title or '',
  }, function(value)
    if value == nil then
      return
    end

    value = vim.trim(value)
    vim.b[terminal.buf].config_terminal_manual_title = value ~= '' and value or nil
    sync_title(terminal)
  end)
end

function M.pick()
  local terminals = Snacks.terminal.list()
  if #terminals == 0 then
    Snacks.notify.warn('No terminals')
    return
  end

  local items = {}
  for _, terminal in ipairs(terminals) do
    items[#items + 1] = {
      text = sync_title(terminal),
      terminal = terminal,
    }
  end

  hide_visible_terminals()
  Snacks.picker.pick({
    title = 'Terminals',
    items = items,
    format = 'text',
    preview = 'none',
    confirm = function(picker, item)
      picker:close()
      focus_terminal(item.terminal)
    end,
  })
end

return M
