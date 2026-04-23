return {
  'nvim-mini/mini.files',
  version = '*',
  opts = {
    mappings = {
      go_in = '<C-l>',
      go_in_plus = 'L',
      go_out = '<C-h>',
      go_out_plus = 'H',
    },
  },
  config = function(_, opts)
    require('mini.files').setup(opts)

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
