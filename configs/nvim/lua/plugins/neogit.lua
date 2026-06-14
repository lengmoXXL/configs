return {
  'NeogitOrg/neogit',
  cmd = { 'Neogit', 'NeogitLogCurrent' },
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit' },
    { '<leader>gf', '<cmd>NeogitLogCurrent<cr>', desc = 'Neogit File History' },
  },
  opts = {
    integrations = {
      codediff = true,
    },
    diff_viewer = 'codediff',
  },
}
