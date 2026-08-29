-- 让当前 tab 的 N 个文件窗口始终显示最近使用的 N 个 buffer：
-- 最左列最新，向右依次次新。:WatchBuffers 切换开关。
local M = { enabled = true }

local mrus = {} -- tabpage -> buffer 号列表，最新在前
local last_cursor = {}
local in_sync = false

local function track_mru(buf)
  if in_sync or not (vim.bo[buf].buflisted and vim.bo[buf].buftype == '') then
    return
  end
  local tab = vim.api.nvim_get_current_tabpage()
  local mru = mrus[tab]
  if not mru then
    mru = {}
    mrus[tab] = mru
  end
  for i, b in ipairs(mru) do
    if b == buf then
      table.remove(mru, i)
      break
    end
  end
  table.insert(mru, 1, buf)
end

local function prune_mru(buf)
  last_cursor[buf] = nil
  for _, mru in pairs(mrus) do
    for i, b in ipairs(mru) do
      if b == buf then
        table.remove(mru, i)
        break
      end
    end
  end
end

local function file_wins()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_get_config(win).relative == '' and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
      table.insert(wins, win)
    end
  end
  table.sort(wins, function(a, b)
    local pa, pb = vim.api.nvim_win_get_position(a), vim.api.nvim_win_get_position(b)
    if pa[2] ~= pb[2] then
      return pa[2] < pb[2]
    end
    return pa[1] < pb[1]
  end)
  return wins
end

function M.sync()
  local wins = file_wins()
  local mru = mrus[vim.api.nvim_get_current_tabpage()]
  if #wins < 2 or not mru or #mru < #wins then
    return
  end

  for _, win in ipairs(wins) do
    last_cursor[vim.api.nvim_win_get_buf(win)] = vim.api.nvim_win_get_cursor(win)
  end

  in_sync = true
  for i = 1, #wins do
    local win, buf = wins[i], mru[i]
    if vim.api.nvim_win_get_buf(win) ~= buf then
      pcall(vim.api.nvim_win_set_buf, win, buf)
      local pos = last_cursor[buf]
      if pos then
        pcall(vim.api.nvim_win_set_cursor, win, pos)
      end
    end
  end
  -- 焦点跟随最新 buffer 到最左栏；仅在当前窗口是文件窗口时跟随
  local cur = vim.api.nvim_get_current_win()
  if vim.tbl_contains(wins, cur) and vim.api.nvim_win_get_buf(cur) ~= mru[1] then
    vim.api.nvim_set_current_win(wins[1])
  end
  in_sync = false
end

local function schedule_sync()
  if M.enabled and not in_sync then
    vim.schedule(M.sync)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('UserBufferColumns', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      track_mru(args.buf)
      schedule_sync()
    end,
  })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      prune_mru(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ 'WinNew', 'WinClosed', 'TabEnter' }, {
    group = group,
    callback = schedule_sync,
  })
  vim.api.nvim_create_user_command('WatchBuffers', function()
    M.enabled = not M.enabled
    if M.enabled then
      M.sync()
    end
    vim.notify('buffer watch ' .. (M.enabled and 'on' or 'off'))
  end, { desc = '文件窗口跟随最近 buffer（左侧最新）' })
end

return M
