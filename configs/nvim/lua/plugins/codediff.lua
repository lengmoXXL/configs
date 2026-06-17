return {
  'esmuellert/codediff.nvim',
  cmd = { 'CodeDiff' },
  keys = {
    { '<leader>gw', '<cmd>CodeDiff<cr>', desc = 'CodeDiff Workspace' },
  },
  opts = {
    keymaps = {
      view = {
        focus_explorer = '<leader>ge',
      },
      explorer = {
        restore = 'x',
      },
    },
    explorer = {
      focus_on_select = true,
    },
  },
}
