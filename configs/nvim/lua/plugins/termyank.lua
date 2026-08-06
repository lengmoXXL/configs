return {
  'hawknewton/termyank.nvim',
  event = { 'TermOpen', 'TermEnter' },
  config = function()
    require('termyank').disable()
  end,
}
