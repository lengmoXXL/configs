return {
  'nvim-mini/mini.files',
  version = '*',
  keys = {
    {
      "<leader>e",
      function()
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      end,
      desc = "Open mini.files (current file location)",
    },
    {
      "<leader>E",
      function()
        MiniFiles.open(vim.fn.getcwd())
      end,
      desc = "Open mini.files (cwd)",
    },
  },
}