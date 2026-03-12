return {
  "yonatan-perel/lake-dweller.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("lake-dweller")
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3c1c1c", fg = "#ff5555" })
    vim.opt.fillchars:append({ diff = " " })
  end,
}