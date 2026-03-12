return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview window" },
    { "<leader>gh", "<cmd>DiffviewOpen HEAD^<cr>", desc = "Open Diffview window" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Open Diffview window" },
    { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview window" },
  },
}