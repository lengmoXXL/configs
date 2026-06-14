return {
  'esmuellert/codediff.nvim',
  cmd = { 'CodeDiff' },
  opts = {
    keymaps = {
      view = {
        focus_explorer = '<leader>je',
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
