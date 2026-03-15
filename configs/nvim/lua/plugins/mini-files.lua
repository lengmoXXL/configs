return {
  'nvim-mini/mini.files',
  version = '*',
  opts = {},
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
