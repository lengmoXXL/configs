-- bufshift - 双列 buffer 管理（PaperWM 风格的简化版）
--
-- 布局：固定左右两列。
--   光标在左列时打开 buffer  -> 在右列打开
--   光标在右列时打开 buffer  -> 右列内容左移，新 buffer 在右列打开
--   关闭                     -> 左列右移补位，左列填入最近使用的 buffer
--   gd                       -> 定义按同样规则在右列打开

local M = {}

local mru = {}    -- bufnr 列表，[1] 为最近使用
local left, right -- 左右两列的 winid

local function buf_ok(b)
  return b and vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
end

local function win_ok(w)
  return w and vim.api.nvim_win_is_valid(w)
end

local function push(b)
  for i, x in ipairs(mru) do
    if x == b then
      table.remove(mru, i)
      break
    end
  end
  table.insert(mru, 1, b)
end

local function recent(except)
  for _, b in ipairs(mru) do
    if buf_ok(b) and not vim.tbl_contains(except, b) then
      return b
    end
  end
end

local function wbuf(w)
  return vim.api.nvim_win_get_buf(w)
end

-- 左右两列任一失效（被 :q 关掉等）时，以当前窗口为左列重建布局
local function ensure_layout()
  if win_ok(left) and win_ok(right) then
    return
  end
  left = vim.api.nvim_get_current_win()
  vim.cmd("rightbelow vsplit")
  right = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(left)
  push(wbuf(left))
end

function M.open(b)
  if not buf_ok(b) then
    return
  end
  ensure_layout()
  if b == wbuf(right) then
    vim.api.nvim_set_current_win(right)
    return
  end
  if vim.api.nvim_get_current_win() == right then
    local displaced = wbuf(left)
    vim.api.nvim_win_set_buf(left, wbuf(right))
    push(displaced)
  end
  vim.api.nvim_win_set_buf(right, b)
  vim.api.nvim_set_current_win(right)
  push(b)
end

function M.close()
  ensure_layout()
  local closed = wbuf(right)
  -- 左列右移补位
  vim.api.nvim_win_set_buf(right, wbuf(left))
  -- 左列填入最近使用的 buffer
  local fill = recent({ closed, wbuf(right) })
  if fill then
    vim.api.nvim_win_set_buf(left, fill)
  else
    -- 没有历史了：收掉左列，只留右列
    vim.api.nvim_win_close(left, false)
    left, right = right, nil
  end
  push(wbuf(right))
end

-- snacks picker 选 buffer，走 M.open 布局
function M.pick_buffer()
  Snacks.picker.buffers({
    confirm = function(picker, item)
      picker:close()
      if item and item.buf then
        M.open(item.buf)
      end
    end,
  })
end

-- gd：定义在右列打开（多结果取第一个）
function M.goto_definition()
  vim.lsp.buf.definition({
    on_list = function(list)
      local item = list.items[1]
      if not item then
        return
      end
      local b = item.bufnr
      if not (b and buf_ok(b)) then
        b = vim.fn.bufadd(item.filename)
        vim.fn.bufload(b)
      end
      M.open(b)
      vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(item.col - 1, 0) })
      vim.cmd("normal! zz")
    end,
  })
end

function M.setup()
  vim.o.splitright = true
  vim.o.equalalways = true

  -- <leader>, 和 gd 在 plugins/snacks.lua 里指向本模块
  vim.keymap.set("n", "<leader>bc", M.close, { desc = "Close Right Column" })

  vim.api.nvim_create_user_command("Bopen", function(opts)
    M.open(vim.fn.bufnr(opts.args))
  end, { nargs = 1, complete = "buffer" })

  -- 外部途径（:e、:b、文件树等）打开的 buffer 也记入 MRU
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(ev)
      if vim.bo[ev.buf].buflisted then
        push(ev.buf)
      end
    end,
  })
end

return M
