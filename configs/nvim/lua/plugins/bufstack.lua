return {
  'BibekBhusal0/bufstack.nvim',
  lazy = false,
  opts = {
    max_tracked = 16,
    shorten_path = true
  },
  keys = {
    { '<leader>bn', '<Cmd>BufStackNext<CR>', desc = 'Navigates to the next tracked buffer.' },
    { '<leader>bp', '<Cmd>BufStackPrev<CR>', desc = 'Navigates to the previous tracked buffer.' },
  }
}
