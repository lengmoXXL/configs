return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  opts = {
    bullet = {
      icons = { '•', '◦' },
    },
    indent = { enabled = true, skip_heading = true },
    heading = { border = true },
    priority = 10,
  },
}
