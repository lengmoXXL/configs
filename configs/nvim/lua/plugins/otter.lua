return {
  'jmbuhr/otter.nvim',
  ft = 'markdown',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {},
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('UserOtterActivate', { clear = true }),
      pattern = 'markdown',
      callback = function()
        -- markdown 里的代码块多为节选片段，诊断会误报；只保留补全和跳转
        require('otter').activate(nil, true, false)
      end,
    })
  end,
}
