local M = {}

function M.pick()
  local items = {}
  local rows = {}
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()
  local index_width = #tostring(#tabpages)
  local title_width = 0

  local function buf_name(buf, full_path)
    local buftype = vim.bo[buf].buftype
    local filetype = vim.bo[buf].filetype
    local name = vim.api.nvim_buf_get_name(buf)

    if buftype == 'terminal' then
      local command = name:match('term://.*//%d+:(.*)$')
      if command and command ~= '' then
        return 'Terminal: ' .. vim.fn.fnamemodify(command, ':t')
      end
      return 'Terminal'
    end

    if buftype == 'quickfix' then
      return 'Quickfix'
    end

    if buftype == 'help' or filetype == 'help' then
      return name == '' and 'Help' or 'Help: ' .. vim.fn.fnamemodify(name, ':t')
    end

    if buftype ~= '' and buftype ~= 'acwrite' then
      return name == '' and '[' .. buftype .. ']' or '[' .. buftype .. '] ' .. vim.fn.fnamemodify(name, ':t')
    end

    if name == '' then
      return '[No Name]'
    end

    if full_path then
      return vim.fn.fnamemodify(name, ':~:.')
    end

    return vim.fn.fnamemodify(name, ':t')
  end

  for index, tabpage in ipairs(tabpages) do
    local win = vim.api.nvim_tabpage_get_win(tabpage)
    local buf = vim.api.nvim_win_get_buf(win)
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    local seen = { [buf] = true }
    local modified = vim.bo[buf].modified
    local other_names = {}

    for _, other_win in ipairs(wins) do
      local other_buf = vim.api.nvim_win_get_buf(other_win)
      if vim.bo[other_buf].modified then
        modified = true
      end
      if not seen[other_buf] then
        seen[other_buf] = true
        other_names[#other_names + 1] = buf_name(other_buf, false)
      end
    end

    local title = buf_name(buf, true)
    if modified then
      title = title .. ' [+]'
    end

    title_width = math.max(title_width, vim.fn.strdisplaywidth(title))
    rows[#rows + 1] = {
      marker = tabpage == current_tabpage and '*' or ' ',
      index = index,
      title = title,
      win_count = #wins,
      other_names = table.concat(other_names, ', '),
      tabpage = tabpage,
    }
  end

  for _, row in ipairs(rows) do
    local padding = string.rep(' ', math.max(2, title_width - vim.fn.strdisplaywidth(row.title) + 2))
    local win_label = row.win_count == 1 and 'win' or 'wins'
    local text = string.format('%s %' .. index_width .. 'd  %s%s%d %s',
      row.marker,
      row.index,
      row.title,
      padding,
      row.win_count,
      win_label
    )

    if row.other_names ~= '' then
      text = text .. ' | ' .. row.other_names
    end

    items[#items + 1] = {
      text = text,
      tabpage = row.tabpage,
    }
  end

  Snacks.picker.pick({
    title = 'Tabs',
    items = items,
    format = 'text',
    preview = 'none',
    confirm = function(picker, item)
      picker:close()
      if item and vim.api.nvim_tabpage_is_valid(item.tabpage) then
        vim.api.nvim_set_current_tabpage(item.tabpage)
      end
    end,
  })
end

function M.close()
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  local fallback_tabpage = nil
  local next_tabpage = nil
  local non_default_count = 0

  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    local is_default = false
    if #wins == 1 then
      local buf = vim.api.nvim_win_get_buf(wins[1])
      is_default = vim.api.nvim_buf_get_name(buf) == ''
        and not vim.bo[buf].modified
        and vim.bo[buf].buftype == ''
    end

    if tabpage == current_tabpage and is_default then
      vim.cmd('confirm quitall')
      return
    end

    if is_default then
      if tabpage ~= current_tabpage and not fallback_tabpage then
        fallback_tabpage = tabpage
      end
    else
      non_default_count = non_default_count + 1
      if tabpage ~= current_tabpage and not next_tabpage then
        next_tabpage = tabpage
      end
    end
  end

  if non_default_count > 1 then
    pcall(vim.cmd, 'confirm tabclose')
    if not vim.api.nvim_tabpage_is_valid(current_tabpage)
      and next_tabpage
      and vim.api.nvim_tabpage_is_valid(next_tabpage) then
      vim.api.nvim_set_current_tabpage(next_tabpage)
    end
    return
  end

  local created_fallback = false
  if not fallback_tabpage then
    vim.cmd('tabnew')
    fallback_tabpage = vim.api.nvim_get_current_tabpage()
    created_fallback = true
  end

  vim.api.nvim_set_current_tabpage(current_tabpage)
  pcall(vim.cmd, 'confirm tabclose')

  if vim.api.nvim_tabpage_is_valid(current_tabpage) then
    if created_fallback and vim.api.nvim_tabpage_is_valid(fallback_tabpage) then
      vim.api.nvim_set_current_tabpage(fallback_tabpage)
      vim.cmd('tabclose')
    end
    vim.api.nvim_set_current_tabpage(current_tabpage)
  elseif vim.api.nvim_tabpage_is_valid(fallback_tabpage) then
    vim.api.nvim_set_current_tabpage(fallback_tabpage)
  end
end

return M
