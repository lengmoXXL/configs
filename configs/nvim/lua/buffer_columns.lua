-- 让当前 tab 的 N 个文件窗口始终显示最近使用的 N 个 buffer：
-- 最左列最新，向右依次次新。:WatchBuffers 切换开关。
local M = { enabled = true }

local mrus = {} -- tabpage -> buffer 号列表，最新在前
local last_cursor = {}
local win_buf = {} -- 每个窗口当前显示的 buffer，用于区分焦点移动和内容变化
local in_sync = false

local function track_mru(buf)
  if in_sync or not (vim.bo[buf].buflisted and vim.bo[buf].buftype == '') then
    return
  end
  local win = vim.api.nvim_get_current_win()
  if win_buf[win] == buf then
    return -- 焦点移动，窗口内容没变，不算最近使用
  end
  win_buf[win] = buf
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
      if pcall(vim.api.nvim_win_set_buf, win, buf) then
        win_buf[win] = buf
      end
      local pos = last_cursor[buf]
      if pos then
        pcall(vim.api.nvim_win_set_cursor, win, pos)
      end
    end
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
    callback = function(args)
      if args.event == 'WinClosed' then
        win_buf[tonumber(args.match)] = nil
      end
      schedule_sync()
    end,
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
