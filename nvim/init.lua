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
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>fH", "<cmd>Telescope man_pages<cr>", desc = "Man pages" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>fC", "<cmd>Telescope command_history<cr>", desc = "Command history" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fm", "<cmd>Telescope man_pages<cr>", desc = "Man pages" },
    },
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
    version = '1.*',
    opts = {
    },
  },
  { 'nvim-mini/mini.files', version = '*',
    keys = {
      {
        "<leader>e",
        function()
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        end,
        desc = "Open mini.files (current file location)",
      },
      {
        "<leader>eC",
        function()
          MiniFiles.open(vim.fn.getcwd())
        end,
        desc = "Open mini.files (cwd)",
      },
    },
  },
  { 'sindrets/diffview.nvim',
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Toggle Diffview window" },
    },
  },
})

-- common
vim.opt.number = true
vim.g.mapleader = " "

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

-- mini.files
require('mini.files').setup()
require('diffview').setup()
