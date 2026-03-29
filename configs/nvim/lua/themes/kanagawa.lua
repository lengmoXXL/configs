return {
  "rebelot/kanagawa.nvim",
  lazy = true,
  opts = {
    commentStyle = { italic = false },
    keywordStyle = { italic = false },
    overrides = function(colors)
      return {
        BlinkCmpMenu = { bg = colors.palette.sumiInk0, fg = colors.palette.fujiWhite },
        BlinkCmpMenuBorder = { bg = colors.palette.sumiInk0, fg = colors.palette.sumiInk3 },
        BlinkCmpMenuSelection = { bg = colors.palette.sumiInk3, fg = colors.palette.fujiWhite },
        BlinkCmpLabel = { fg = colors.palette.fujiWhite },
        BlinkCmpLabelMatch = { fg = colors.palette.roninYellow },
        BlinkCmpKind = { fg = colors.palette.crystalBlue },
      }
    end,
  },
}
