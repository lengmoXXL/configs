vim.o.number = true
vim.o.tabstop = 4
vim.o.wrap = false
vim.o.exrc = true
-- put in front of lazy
vim.g.mapleader = " "

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

vim.opt.fillchars:append({ diff = ' ' })

-- lsp
-- Diffview uses virtual buffers. Do not start or attach any LSP client there.
if not vim.lsp._start_without_diffview_guard then
  vim.lsp._start_without_diffview_guard = vim.lsp.start
  vim.lsp.start = function(config, opts)
    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then
      bufnr = vim.api.nvim_get_current_buf()
    end

    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match('^diffview://') then
      return
    end

    return vim.lsp._start_without_diffview_guard(config, opts)
  end
end

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

-- markdown-oxide LSP (替代 marksman，性能更好)
vim.lsp.enable('markdown_oxide')

vim.lsp.enable('typos_lsp')
vim.lsp.enable('ts_ls')
vim.lsp.enable('bashls')
vim.lsp.enable('lua_ls')

-- ds-pinyin-lsp 拼音输入法
-- 默认在 markdown/org 自动启动，其他文件可通过 :PinyinLspToggle 手动启动
vim.lsp.config('ds_pinyin_lsp', {
  init_options = {
    db_path = vim.fn.expand('~/.local/share/ds-pinyin-lsp/dict.db3'),
  },
})
vim.lsp.enable('ds_pinyin_lsp')

-- 手动启动/停止拼音 LSP (用于非 markdown/org 文件)
vim.api.nvim_create_user_command('PinyinLspToggle', function()
  local clients = vim.lsp.get_clients({ name = 'ds_pinyin_lsp', bufnr = 0 })
  if #clients > 0 then
    for _, client in ipairs(clients) do
      client:stop()
    end
    print('ds-pinyin-lsp stopped')
  else
    -- 获取内置配置并移除 filetype 限制
    local config = vim.lsp.config['ds_pinyin_lsp']
    if config then
      config.filetypes = nil
      vim.lsp.start(config)
      print('ds-pinyin-lsp started')
    end
  end
end, { desc = 'Toggle ds-pinyin-lsp for current buffer' })

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

-- clipboard: OSC 52 for SSH/terminal without X11
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- system clipboard
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank to clipboard' })
vim.keymap.set('n', '<leader>yy', '"+yy', { desc = 'Yank line to clipboard' })

-- 复制文件位置 (可视模式下)
vim.keymap.set('v', '<leader>yl', function()
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  local file = vim.fn.expand('%:t')
  local location = file .. ':' .. start_line
  if start_line ~= end_line then
    location = location .. '-' .. end_line
  end
  vim.fn.setreg('+', location)
end, { desc = 'Yank file location' })
