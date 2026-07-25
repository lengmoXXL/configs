return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  opts = {
    max_file_size = 0.2,
    nested = false,
    bullet = {
      icons = { '•', '◦' },
    },
    checkbox = {
      checked = {
        icon = '󰄲 ',
      }
    },
    indent = { enabled = true, skip_heading = true },
    sign = { enabled = false },
    heading = { icons = { '󰉫 ', '󰉬 ', '󰉭 ', '󰉮 ', '󰉯 ', '󰉰 ' } },
    completions = {
      blink = { enabled = true },
      lsp = { enabled = true },
    }
  },
}
