-- Detect binary files and refuse to open them.
-- Reads the first 8KB; if it contains a null byte, treat as binary.
local group = vim.api.nvim_create_augroup('binary_guard', { clear = true })

vim.api.nvim_create_autocmd('BufReadPre', {
  group = group,
  callback = function(opts)
    local file = opts.file
    if file == '' then return end
    local f = io.open(file, 'rb')
    if not f then return end
    local chunk = f:read(8192) or ''
    f:close()
    if chunk:find('\0', 1, true) then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(opts.buf) then
          vim.api.nvim_buf_delete(opts.buf, { force = true })
        end
        vim.notify('二进制文件，已拒绝打开: ' .. file, vim.log.levels.WARN)
      end)
    end
  end,
})
