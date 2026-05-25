return {
  'nvim-mini/mini.files',
  version = '*',
  cmd = { 'MiniFilesToggleSort' },
  opts = {
    mappings = {
      go_in = '<C-l>',
      go_in_plus = 'L',
      go_out = '<C-h>',
      go_out_plus = 'H',
    },
  },
  config = function(_, opts)
    local sort_ascending = 'name_asc'
    local sort_descending = 'name_desc'
    local project_state = require('project_state')

    local get_sort_mode = function()
      if project_state.get('mini_files_sort', sort_ascending) == sort_descending then
        return sort_descending
      end
      return sort_ascending
    end

    local sort_by_name = function(entries)
      local descending = get_sort_mode() == sort_descending
      local compare = function(left, right)
        if descending then
          return left > right
        end
        return left < right
      end

      table.sort(entries, function(a, b)
        if a.fs_type ~= b.fs_type then
          return a.fs_type == 'directory'
        end

        local a_name, b_name = a.name:lower(), b.name:lower()
        if a_name == b_name then
          if a.name == b.name then
            return compare(a.path, b.path)
          end
          return compare(a.name, b.name)
        end
        return compare(a_name, b_name)
      end)

      return entries
    end

    opts.content = opts.content or {}
    opts.content.sort = sort_by_name

    local mini_files = require('mini.files')
    mini_files.setup(opts)

    vim.api.nvim_create_user_command('MiniFilesToggleSort', function()
      local next_mode = get_sort_mode() == sort_ascending and sort_descending or sort_ascending
      project_state.set('mini_files_sort', next_mode)
      mini_files.refresh({ content = { sort = sort_by_name } })
      vim.notify(('mini.files sort: %s'):format(next_mode == sort_ascending and 'name ascending' or 'name descending'))
    end, { desc = 'Toggle mini.files filename sort order', force = true })
  end,
  keys = {
    {
      "<leader>e",
      function()
        local mini_files = require('mini.files')
        if not mini_files.close() then
          mini_files.open(vim.api.nvim_buf_get_name(0))
          mini_files.reveal_cwd()
        end
      end,
      desc = "Toggle mini.files (current file location)",
    },
    {
      "<leader>E",
      function()
        require('mini.files').open(vim.fn.getcwd())
      end,
      desc = "Open mini.files (cwd)",
    },
  },
}
