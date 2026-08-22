vim.o.number = true
vim.o.tabstop = 4
vim.o.wrap = false
vim.o.exrc = true
vim.o.cmdheight = 0
vim.o.wildmode = "longest:full,full"
vim.o.showtabline = 0
vim.o.title = true
vim.o.titlestring = "nvim: %{fnamemodify(getcwd(), ':t')}"
-- put in front of lazy
vim.g.mapleader = " "
vim.g.clipboard = "osc52"
vim.o.autowriteall = true
vim.o.smoothscroll = true
vim.opt.fillchars:append({ eob = " " }) -- 隐藏空行的 ~

require('project_filetypes').setup()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { import = "plugins" },
  { import = "themes" },
})

-- theme
vim.cmd.colorscheme("vscode")

vim.lsp.config('clangd', {
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  cmd = {
    'clangd',
    '--header-insertion=never',
    '--function-arg-placeholders=0',
    '--background-index',
  },
})
vim.lsp.enable('clangd')
vim.lsp.enable('pyright')
vim.lsp.enable('gopls')
vim.lsp.enable('rust_analyzer')

-- markdown-oxide LSP (替代 marksman，性能更好)
vim.lsp.enable('markdown_oxide')

vim.lsp.enable('typos_lsp')
vim.lsp.enable('ts_ls')
vim.lsp.enable('bashls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('starpls')

-- switch source/header (clangd)
vim.keymap.set('n', '<leader>ch', '<cmd>LspClangdSwitchSourceHeader<cr>', { desc = 'Switch source/header' })

-- diagnostic
vim.diagnostic.config({
  signs = false,
  underline = true,         -- 错误代码下划线
  update_in_insert = false, -- 插入模式不更新
  virtual_text = {          -- 行尾详细信息
    prefix = '●',
    spacing = 4,
    severity = { min = vim.diagnostic.severity.ERROR, max = vim.diagnostic.severity.ERROR },
  },
})

-- system clipboard
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank to clipboard' })

-- 复制项目内文件位置 (可视模式下)
vim.keymap.set('v', '<leader>ly', function()
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(file, { '.git' }) or vim.fn.getcwd()
  file = vim.fs.relpath(root, file) or file
  local location = file .. ':' .. start_line
  if start_line ~= end_line then
    location = location .. '-' .. end_line
  end
  vim.fn.setreg('+', location)
end, { desc = 'Yank file location' })

-- window navigation: C-w L/H jump to rightmost/leftmost window
vim.keymap.set('n', '<C-w>L', function()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  vim.api.nvim_set_current_win(wins[#wins])
end, { desc = 'Jump to rightmost window' })

vim.keymap.set('n', '<C-w>H', function()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  vim.api.nvim_set_current_win(wins[1])
end, { desc = 'Jump to leftmost window' })

-- C-w F: open file:line under cursor in a right vertical split
vim.keymap.set('n', '<C-w>F', '<cmd>botright vertical wincmd F<cr>', { desc = 'Open file:line in right split' })
