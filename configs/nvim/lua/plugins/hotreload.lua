return {
  'diogo464/hotreload.nvim',
  lazy = false,
  opts = {
    silent = false,
  },
  config = function(_, opts)
    require('hotreload').setup(opts)

    vim.api.nvim_create_autocmd('FileChangedShell', {
      group = vim.api.nvim_create_augroup('UserCloseDeletedFileBuffers', { clear = true }),
      callback = function(args)
        if vim.v.fcs_reason ~= 'deleted' then
          vim.v.fcs_choice = 'ask'
          return
        end

        vim.v.fcs_choice = ''
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end

          local buf_name = vim.api.nvim_buf_get_name(args.buf)
          if vim.bo[args.buf].modified then
            vim.notify(('Buffer has unsaved changes, skipped closing: %s'):format(buf_name), vim.log.levels.WARN)
            return
          end

          Snacks.bufdelete.delete({ buf = args.buf, wipe = true })
        end)
      end,
    })
  end,
}
