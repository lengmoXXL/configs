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

local function toggle_diffview(command)
  return function()
    local tabpage = find_diffview_tab()

    if tabpage == vim.api.nvim_get_current_tabpage() then
      vim.cmd('DiffviewClose')
    elseif tabpage then
      vim.api.nvim_set_current_tabpage(tabpage)
    else
      vim.cmd(command)
    end
  end
end

return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  keys = {
    { "<leader>jd", toggle_diffview('DiffviewOpen'), desc = "Toggle Diffview" },
    { "<leader>jh", toggle_diffview('DiffviewOpen HEAD^'), desc = "Toggle Diffview HEAD^" },
    { "<leader>jH", toggle_diffview('DiffviewFileHistory'), desc = "Toggle Diffview file history" },
  },
}
