return {
  'nanozuki/tabby.nvim',
  opts = {
    line = function(line)
      return {
        line.tabs().foreach(function(tab)
          return {
            ' ',
            tab.number(),
            ':',
            tab.name(),
            ' ',
            tab.close_btn('x'),
            ' ',
            hl = tab.is_current() and 'TabLineSel' or 'TabLine',
          }
        end),
        hl = 'TabLineFill',
      }
    end,
  },
}
