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
vim.cmd.colorscheme("kanagawa-dragon")
vim.opt.fillchars:append({ diff = ' ' })

-- lsp
vim.lsp.config('clangd', {
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  cmd = {
    'clangd',
    '--header-insertion=never',
    '--function-arg-placeholders=0',
    '--background-index',
  },
  root_dir = function(bufnr, on_dir)
    -- 虚拟 buffer (如 diffview://) 不调用 on_dir，LSP 不启动
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match('^diffview://') then
      return
    end
    local root = vim.fs.root(bufnr, { '.clangd', '.git', 'compile_commands.json' })
    if root then
      on_dir(root)
    end
  end,
})
vim.lsp.enable('clangd')
vim.lsp.enable('pyright')
vim.lsp.enable('gopls')
vim.lsp.enable('marksman')
vim.lsp.enable('typos_lsp')
vim.lsp.enable('ts_ls')
vim.lsp.enable('bashls')

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
      vim.lsp.stop_client(client.id)
    end
    print('ds-pinyin-lsp stopped')
  else
    -- 获取内置配置并移除 filetype 限制
    local config = vim.lsp.config['ds_pinyin_lsp']
    config.filetypes = nil
    vim.lsp.start(config)
    print('ds-pinyin-lsp started')
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

-- 系统剪贴板
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

