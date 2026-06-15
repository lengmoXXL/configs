return {
  'NeogitOrg/neogit',
  cmd = { 'Neogit', 'NeogitLogCurrent' },
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit' },
    { '<leader>gf', '<cmd>NeogitLogCurrent<cr>', desc = 'Neogit File History' },
    { '<leader>gl', '<cmd>Neogit log<cr>', desc = 'Neogit Log History' },
  },
  opts = {
    integrations = {
      codediff = true,
    },
    diff_viewer = 'codediff',
  },
}
