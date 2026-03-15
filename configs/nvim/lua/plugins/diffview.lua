return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  keys = {
    { "<leader>jd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview window" },
    { "<leader>jh", "<cmd>DiffviewOpen HEAD^<cr>", desc = "Open Diffview window" },
    { "<leader>jH", "<cmd>DiffviewFileHistory<cr>", desc = "Open Diffview window" },
    { "<leader>jc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview window" },
  },
}
