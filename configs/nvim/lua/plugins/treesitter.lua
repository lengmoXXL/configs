return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'html',
      callback = function()
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.opt_local.foldlevel = 99
      end,
    })
  end,
  opts = {
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = {
      'c',
      'cpp',
      'go',
      'html',
      'json',
      'json5',
      'lua',
      'markdown',
      'python',
      'regex',
    },
  },
}
