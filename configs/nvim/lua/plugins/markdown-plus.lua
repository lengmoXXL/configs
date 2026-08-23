local function get_wiki_link_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local search_start = 1

  while true do
    local start_col, end_col, body = line:find("%[%[([^%]]+)%]%]", search_start)
    if not start_col then
      return nil
    end

    if col >= start_col and col <= end_col then
      return body
    end

    search_start = end_col + 1
  end
end

local function wiki_link_to_path(link)
  local target = vim.trim(link)

  target = target:gsub("|.*$", "")
  target = target:gsub("#.*$", "")
  target = vim.trim(target)

  if target == "" then
    return nil
  end

  if not target:match("%.[^/\\]+$") then
    target = target .. ".md"
  end

  local current_dir = vim.fn.expand("%:p:h")
  return vim.fs.normalize(current_dir .. "/" .. target)
end

local function open_or_create_wiki_link()
  local link = get_wiki_link_at_cursor()
  if not link then
    return false
  end

  local path = wiki_link_to_path(link)
  if not path then
    return false
  end

  local dir = vim.fs.dirname(path)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  if vim.fn.filereadable(path) == 0 then
    local fd = assert(vim.uv.fs_open(path, "w", 420))
    vim.uv.fs_close(fd)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  return true
end

return {
  'yousefhadder/markdown-plus.nvim',
  ft = 'markdown',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('UserMarkdownSelectionKeymaps', { clear = true }),
      pattern = 'markdown',
      callback = function(args)
        vim.keymap.set('x', '<Tab>', '>gv', {
          buffer = args.buf,
          desc = 'Markdown list indent selection',
          noremap = true,
        })
        vim.keymap.set('x', '<S-Tab>', '<gv', {
          buffer = args.buf,
          desc = 'Markdown list outdent selection',
          noremap = true,
        })
      end,
    })
  end,
  keys = {
    { '<CR>', '<Plug>(MarkdownPlusListEnter)', mode = 'i', ft = 'markdown', desc = 'Markdown list enter' },
    { '<A-CR>', '<Plug>(MarkdownPlusListShiftEnter)', mode = 'i', ft = 'markdown', desc = 'Markdown list continue content' },
    { '<Tab>', '<Plug>(MarkdownPlusListIndent)', mode = 'i', ft = 'markdown', desc = 'Markdown list indent' },
    { '<S-Tab>', '<Plug>(MarkdownPlusListOutdent)', mode = 'i', ft = 'markdown', desc = 'Markdown list outdent' },
    { '<BS>', '<Plug>(MarkdownPlusListBackspace)', mode = 'i', ft = 'markdown', desc = 'Markdown list smart backspace' },
    { 'o', '<Plug>(MarkdownPlusNewListItemBelow)', mode = 'n', ft = 'markdown', desc = 'Markdown new list item below' },
    { 'O', '<Plug>(MarkdownPlusNewListItemAbove)', mode = 'n', ft = 'markdown', desc = 'Markdown new list item above' },
    { '<localleader>mx', '<Plug>(MarkdownPlusToggleCheckbox)', mode = 'n', ft = 'markdown', desc = 'Markdown toggle checkbox' },
    { '<localleader>mx', '<Plug>(MarkdownPlusToggleCheckbox)', mode = 'x', ft = 'markdown', desc = 'Markdown toggle checkbox' },
    { '<C-t>', '<Plug>(MarkdownPlusToggleCheckbox)', mode = 'i', ft = 'markdown', desc = 'Markdown toggle checkbox' },
    { '<localleader>mr', '<Plug>(MarkdownPlusRenumberLists)', mode = 'n', ft = 'markdown', desc = 'Markdown renumber lists' },
    { '<localleader>tc', '<Plug>(MarkdownPlusTableCreate)', mode = 'n', ft = 'markdown', desc = 'Markdown table create' },
    { '<localleader>tf', '<Plug>(MarkdownPlusTableFormat)', mode = 'n', ft = 'markdown', desc = 'Markdown table format' },
    { '<localleader>tn', '<Plug>(MarkdownPlusTableNormalize)', mode = 'n', ft = 'markdown', desc = 'Markdown table normalize' },
    { '<localleader>tir', '<Plug>(MarkdownPlusTableInsertRowBelow)', mode = 'n', ft = 'markdown', desc = 'Markdown table insert row below' },
    { '<localleader>tiR', '<Plug>(MarkdownPlusTableInsertRowAbove)', mode = 'n', ft = 'markdown', desc = 'Markdown table insert row above' },
    { '<localleader>tdr', '<Plug>(MarkdownPlusTableDeleteRow)', mode = 'n', ft = 'markdown', desc = 'Markdown table delete row' },
    { '<localleader>tyr', '<Plug>(MarkdownPlusTableDuplicateRow)', mode = 'n', ft = 'markdown', desc = 'Markdown table duplicate row' },
    { '<localleader>tic', '<Plug>(MarkdownPlusTableInsertColumnRight)', mode = 'n', ft = 'markdown', desc = 'Markdown table insert column right' },
    { '<localleader>tiC', '<Plug>(MarkdownPlusTableInsertColumnLeft)', mode = 'n', ft = 'markdown', desc = 'Markdown table insert column left' },
    { '<localleader>tdc', '<Plug>(MarkdownPlusTableDeleteColumn)', mode = 'n', ft = 'markdown', desc = 'Markdown table delete column' },
    { '<localleader>tyc', '<Plug>(MarkdownPlusTableDuplicateColumn)', mode = 'n', ft = 'markdown', desc = 'Markdown table duplicate column' },
    { '<localleader>ta', '<Plug>(MarkdownPlusTableToggleCellAlignment)', mode = 'n', ft = 'markdown', desc = 'Markdown table toggle alignment' },
    { '<localleader>tx', '<Plug>(MarkdownPlusTableClearCell)', mode = 'n', ft = 'markdown', desc = 'Markdown table clear cell' },
    { '<localleader>tmj', '<Plug>(MarkdownPlusTableMoveRowDown)', mode = 'n', ft = 'markdown', desc = 'Markdown table move row down' },
    { '<localleader>tmk', '<Plug>(MarkdownPlusTableMoveRowUp)', mode = 'n', ft = 'markdown', desc = 'Markdown table move row up' },
    { '<localleader>tmh', '<Plug>(MarkdownPlusTableMoveColumnLeft)', mode = 'n', ft = 'markdown', desc = 'Markdown table move column left' },
    { '<localleader>tml', '<Plug>(MarkdownPlusTableMoveColumnRight)', mode = 'n', ft = 'markdown', desc = 'Markdown table move column right' },
    { '<localleader>tt', '<Plug>(MarkdownPlusTableTranspose)', mode = 'n', ft = 'markdown', desc = 'Markdown table transpose' },
    { '<localleader>tsa', '<Plug>(MarkdownPlusTableSortAscending)', mode = 'n', ft = 'markdown', desc = 'Markdown table sort ascending' },
    { '<localleader>tsd', '<Plug>(MarkdownPlusTableSortDescending)', mode = 'n', ft = 'markdown', desc = 'Markdown table sort descending' },
    { '<localleader>tvx', '<Plug>(MarkdownPlusTableToCSV)', mode = 'n', ft = 'markdown', desc = 'Markdown table to CSV' },
    { '<localleader>tvi', '<Plug>(MarkdownPlusTableFromCSV)', mode = 'n', ft = 'markdown', desc = 'Markdown CSV to table' },
    { '<A-h>', '<Plug>(MarkdownPlusTableNavLeft)', mode = 'i', ft = 'markdown', desc = 'Markdown table nav left' },
    { '<A-l>', '<Plug>(MarkdownPlusTableNavRight)', mode = 'i', ft = 'markdown', desc = 'Markdown table nav right' },
    { '<A-k>', '<Plug>(MarkdownPlusTableNavUp)', mode = 'i', ft = 'markdown', desc = 'Markdown table nav up' },
    { '<A-j>', '<Plug>(MarkdownPlusTableNavDown)', mode = 'i', ft = 'markdown', desc = 'Markdown table nav down' },
    -- Wiki link navigation
    {
      '<localleader>gf',
      open_or_create_wiki_link,
      mode = 'n',
      ft = 'markdown',
      desc = 'Open or create wiki link',
    },
  },
  opts = {
    keymaps = {
      enabled = false,
    },
  },
}
