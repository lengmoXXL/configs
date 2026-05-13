return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  opts = {
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = {
      'c',
      'cpp',
      'go',
      'json',
      'json5',
      'lua',
      'markdown',
      'python',
      'regex',
    },
  },
}
