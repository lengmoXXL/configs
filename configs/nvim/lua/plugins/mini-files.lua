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

    local is_deleted_path = function(buf, deleted, deleted_prefix)
      local buf_name = vim.api.nvim_buf_get_name(buf)
      local buf_path = buf_name ~= '' and vim.fs.normalize(buf_name) or nil

      return buf_path and (buf_path == deleted or vim.startswith(buf_path, deleted_prefix))
    end

    local is_listed_normal_buffer = function(buf)
      return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
    end

    local find_fallback_buffer = function(win, current_buf, deleted, deleted_prefix)
      local alternate = vim.api.nvim_win_call(win, function()
        return vim.fn.bufnr('#')
      end)

      if
        alternate > 0
        and alternate ~= current_buf
        and is_listed_normal_buffer(alternate)
        and not is_deleted_path(alternate, deleted, deleted_prefix)
      then
        return alternate
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
          buf ~= current_buf
          and is_listed_normal_buffer(buf)
          and not is_deleted_path(buf, deleted, deleted_prefix)
        then
          return buf
        end
      end

      local fallback = vim.api.nvim_create_buf(true, false)
      vim.bo[fallback].bufhidden = 'wipe'
      return fallback
    end

    local switch_windows_showing_buffer = function(buf, deleted, deleted_prefix)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
          vim.api.nvim_win_set_buf(win, find_fallback_buffer(win, buf, deleted, deleted_prefix))
        end
      end
    end

    local close_deleted_buffers = function(deleted_path)
      if not deleted_path or deleted_path == '' then
        return
      end

      local deleted = vim.fs.normalize(deleted_path)
      local deleted_prefix = deleted:sub(-1) == '/' and deleted or deleted .. '/'

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and is_deleted_path(buf, deleted, deleted_prefix) then
          local buf_name = vim.api.nvim_buf_get_name(buf)

          if vim.bo[buf].modified then
            vim.notify(
              ('Buffer has unsaved changes, skipped closing: %s'):format(buf_name),
              vim.log.levels.WARN
            )
          else
            switch_windows_showing_buffer(buf, deleted, deleted_prefix)

            local ok, err = pcall(vim.api.nvim_buf_delete, buf, {})
            if not ok then
              vim.notify(
                ('Failed to close deleted buffer %s: %s'):format(buf_name, err),
                vim.log.levels.WARN
              )
            end
          end
        end
      end
    end

    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('UserMiniFilesCloseDeletedBuffers', { clear = true }),
      pattern = 'MiniFilesActionDelete',
      callback = function(args)
        close_deleted_buffers(args.data and args.data.from)
      end,
    })
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
