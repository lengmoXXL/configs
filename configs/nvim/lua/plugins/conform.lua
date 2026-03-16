return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      desc = 'Format buffer',
    },
  },
  opts = {
    format_on_save = function(bufnr)
      if vim.bo[bufnr].filetype == 'go' then
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end
      return nil
    end,
    formatters_by_ft = {
      go = { 'gofmt' },
    },
  },
}