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
  config = function(_, opts)
    local keymaps = require('codediff.ui.view.keymaps')
    local setup_keymaps = keymaps.setup_all_keymaps
    local compact = require('codediff.ui.view.compact')
    keymaps.setup_all_keymaps = function(tabpage, ...)
      setup_keymaps(tabpage, ...)
      local session = require('codediff.ui.lifecycle').get_session(tabpage)
      local changes = session and session.stored_diff_result and session.stored_diff_result.changes
      local conflict = session and (session.original_revision == ':2' or session.original_revision == ':3')
      if session and session.compact_mode == nil and not conflict and changes and #changes > 0 then
        compact.enable(tabpage)
      end
    end
    require('codediff').setup(opts)
  end,
  opts = {
    explorer = {
      focus_on_select = true,
    },
    keymaps = {
      view = {
        focus_explorer = '<leader>ge',
      },
    },
  },
}
