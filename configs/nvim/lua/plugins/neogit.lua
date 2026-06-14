return {
  'NeogitOrg/neogit',
  cmd = 'Neogit',
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit' },
  },
  opts = {
    integrations = {
      codediff = true,
    },
    diff_viewer = 'codediff',
  },
}
