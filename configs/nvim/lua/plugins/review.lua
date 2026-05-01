return {
  'lengmoXXL/review-comments.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  event = { 'BufReadPost', 'BufNewFile' },
  cmd = { 'ReviewComments' },
  opts = {},
}
