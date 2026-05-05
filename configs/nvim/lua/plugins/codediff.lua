local codediff_type = nil -- 'open', 'head', 'history'

local function find_codediff_tab()
  local lifecycle = require('codediff.ui.lifecycle')

  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    if lifecycle.get_session(tabpage) then
      return tabpage
    end
  end

  return nil
end

local function close_codediff(tabpage)
  if not tabpage or not vim.api.nvim_tabpage_is_valid(tabpage) then
    return
  end

  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd('tabnew')
  end

  vim.api.nvim_set_current_tabpage(tabpage)
  vim.cmd('tabclose')
  codediff_type = nil
end

local function open_or_switch(command, view_type)
  return function()
    local tabpage = find_codediff_tab()
    if tabpage then
      if codediff_type == view_type then
        vim.api.nvim_set_current_tabpage(tabpage)
        return
      end

      close_codediff(tabpage)
    end

    vim.cmd(command)
    codediff_type = view_type
  end
end

local function toggle_codediff()
  local tabpage = find_codediff_tab()
  if tabpage then
    if tabpage == vim.api.nvim_get_current_tabpage() then
      close_codediff(tabpage)
    else
      vim.api.nvim_set_current_tabpage(tabpage)
    end
  else
    vim.cmd('CodeDiff')
    codediff_type = 'open'
  end
end

return {
  'codediff.nvim',
  url = 'https://github.com/grrru/codediff.nvim.git',
  cmd = { 'CodeDiff' },
  keys = {
    { '<leader>jj', toggle_codediff, desc = 'Toggle CodeDiff' },
    { '<leader>jh', open_or_switch('CodeDiff HEAD^ HEAD', 'head'), desc = 'Open CodeDiff HEAD' },
    { '<leader>jH', open_or_switch('CodeDiff history', 'history'), desc = 'Open CodeDiff history' },
  },
  opts = {
    explorer = {
      focus_on_select = true,
    },
  },
}
