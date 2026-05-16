local function close_codediff()
  local lifecycle = require('codediff.ui.lifecycle')
  local tabpage = nil

  for _, candidate in ipairs(vim.api.nvim_list_tabpages()) do
    if lifecycle.get_session(candidate) then
      tabpage = candidate
      break
    end
  end

  if not tabpage then
    return false
  end

  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd('tabnew')
  end

  if vim.api.nvim_tabpage_is_valid(tabpage) then
    vim.cmd(vim.api.nvim_tabpage_get_number(tabpage) .. 'tabclose')
  end

  return true
end

local function open_codediff(command)
  return function()
    close_codediff()
    vim.schedule(function()
      vim.cmd(command)
    end)
  end
end

return {
  'codediff.nvim',
  url = 'https://github.com/grrru/codediff.nvim.git',
  cmd = { 'CodeDiff' },
  keys = {
    { '<leader>jj', open_codediff('CodeDiff'), desc = 'Open CodeDiff' },
    { '<leader>jh', open_codediff('CodeDiff HEAD^ HEAD'), desc = 'Open CodeDiff HEAD' },
    { '<leader>jc', function()
      local clipboard = vim.trim(vim.fn.getreg('+'))
      local default = clipboard:match('^%x%x%x%x%x%x%x+%x*$') and clipboard or ''
      local commit = vim.trim(vim.fn.input('CodeDiff commit: ', default))
      if commit == '' then
        return
      end

      close_codediff()
      vim.schedule(function()
        vim.api.nvim_cmd({ cmd = 'CodeDiff', args = { commit .. '^', commit } }, {})
      end)
    end, desc = 'Open CodeDiff commit' },
    { '<leader>jf', open_codediff('CodeDiff history %'), desc = 'Open CodeDiff file history' },
    { '<leader>jH', open_codediff('CodeDiff history'), desc = 'Open CodeDiff history' },
  },
  opts = {
    keymaps = {
      view = {
        focus_explorer = '<leader>je',
        next_hunk = false,
        prev_hunk = false,
      },
    },
    explorer = {
      focus_on_select = true,
    },
  },
}
