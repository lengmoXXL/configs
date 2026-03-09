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
  {
    'lunarvim/darkplus.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("darkplus")
    end,
  },
  {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  { 'neovim/nvim-lspconfig' },
  { 
    'nmac427/guess-indent.nvim',
    config = function() require('guess-indent').setup {} end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
  },
  {
    'saghen/blink.cmp',
    opts = {
      sources = {
        default = { 'lsp', 'path', 'buffer' },
      },
      fuzzy = { implementation = "lua" },
    },
  },
})

-- common
vim.opt.number = true
vim.g.mapleader = " "

-- telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Telescope find document symbols' })
vim.keymap.set('n', '<leader>fS', builtin.lsp_workspace_symbols, { desc = 'Telescope find workspace symbols' })

-- lsp
vim.lsp.enable('clangd')
vim.lsp.enable('pyright')
vim.lsp.enable('gopls')
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)        -- 跳转到定义（包括头文件）
vim.keymap.set('n', 'gr', vim.lsp.buf.references)        -- 查看引用
vim.keymap.set('n', 'K', vim.lsp.buf.hover)              -- 查看文档

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
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)      -- 上一个错误
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)      -- 下一个错误
vim.keymap.set('n', '<C-o>', '<C-o>')                    -- 跳回之前的位置
