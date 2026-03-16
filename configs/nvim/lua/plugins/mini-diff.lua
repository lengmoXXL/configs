return {
  'nvim-mini/mini.diff',
  version = '*',
  lazy = false,
  opts = {},
  keys = {
    { '<leader>to', function() require('mini.diff').toggle_overlay() end, desc = 'Toggle diff overlay' },
  }
}
