return {
  'nvim-mini/mini.files',
  version = '*',
  opts = {
    mappings = {
      go_in = '<C-l>',
      go_in_plus = 'L',
      go_out = '<C-h>',
      go_out_plus = 'H',
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        require('mini.files').open(vim.api.nvim_buf_get_name(0))
      end,
      desc = "Open mini.files (current file location)",
    },
    {
      "<leader>E",
      function()
        require('mini.files').open(vim.fn.getcwd())
      end,
      desc = "Open mini.files (cwd)",
    },
  },
}
