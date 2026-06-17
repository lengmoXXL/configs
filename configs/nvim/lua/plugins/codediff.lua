return {
  'esmuellert/codediff.nvim',
  cmd = { 'CodeDiff' },
  keys = {
    {
      '<leader>gw',
      function()
        local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
        if ok then
          for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
            local session = lifecycle.get_session(tabpage)
            local explorer = lifecycle.get_explorer(tabpage)
            if
              session
              and session.mode == 'explorer'
              and explorer
              and not explorer.base_revision
              and not explorer.target_revision
              and not explorer.dir1
              and not explorer.dir2
            then
              vim.api.nvim_set_current_tabpage(tabpage)
              return
            end
          end
        end

        vim.cmd('CodeDiff')
      end,
      desc = 'CodeDiff Workspace',
    },
  },
  opts = {
    keymaps = {
      view = {
        focus_explorer = '<leader>ge',
      },
      explorer = {
        restore = 'x',
      },
    },
    explorer = {
      focus_on_select = true,
    },
  },
}
