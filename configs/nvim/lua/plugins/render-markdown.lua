return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  opts = {
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
