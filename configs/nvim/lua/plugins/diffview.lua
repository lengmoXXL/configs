local diffview_type = nil -- 'open', 'head', 'history'

local function restore_all_unstaged()
  local lib = require('diffview.lib')
  local async = require('diffview.async')
  local vcs_utils = require('diffview.vcs.utils')

  async.void(function()
    local view = lib.get_current_view()
    if not view or not view.files or view.right.type ~= require('diffview.vcs.rev').RevType.LOCAL then
      return
    end

    for _, file in ipairs(view.files.working) do
      async.await(vcs_utils.restore_file(view.adapter, file.path, file.kind))
    end

    view:update_files()
  end)()
end

local function find_diffview_tab()
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)

      if name:match('^diffview://') then
        return tabpage
      end
    end
  end

  return nil
end

local function close_diffview()
  vim.cmd('DiffviewClose')
  diffview_type = nil
end

local function open_or_switch(command, view_type)
  return function()
    local tabpage = find_diffview_tab()
    if tabpage then
      if diffview_type == view_type then
        vim.api.nvim_set_current_tabpage(tabpage)
      else
        vim.api.nvim_set_current_tabpage(tabpage)
        vim.cmd('DiffviewClose')
        vim.cmd(command)
        diffview_type = view_type
      end
    else
      vim.cmd(command)
      diffview_type = view_type
    end
  end
end

return {
  'sindrets/diffview.nvim',
  enabled = false,
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  opts = function()
    local actions = require('diffview.actions')

    return {
      keymaps = {
        file_panel = {
          { 'n', 'd', actions.restore_entry, { desc = 'Restore unstaged entry' } },
          { 'n', 'D', restore_all_unstaged, { desc = 'Restore all unstaged entries' } },
        },
      },
    }
  end,
  keys = {
    { "<leader>jj", function()
        local tabpage = find_diffview_tab()
        if tabpage then
          if tabpage == vim.api.nvim_get_current_tabpage() then
            close_diffview()
          else
            vim.api.nvim_set_current_tabpage(tabpage)
          end
        else
          vim.cmd('DiffviewOpen')
          diffview_type = 'open'
        end
      end, desc = "Toggle Diffview" },
    { "<leader>jh", open_or_switch('DiffviewOpen HEAD^', 'head'), desc = "Open Diffview HEAD^" },
    { "<leader>jH", open_or_switch('DiffviewFileHistory', 'history'), desc = "Open Diffview file history" },
  },
}
