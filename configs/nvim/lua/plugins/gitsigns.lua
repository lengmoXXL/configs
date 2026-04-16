return {
  'lewis6991/gitsigns.nvim',
  event = 'VeryLazy',
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol',
    },
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      local function nav_hunk(direction, target)
        return function()
          if vim.wo.diff then
            local key = direction == 'next' and ']c' or '[c'
            vim.cmd.normal({ key, bang = true })
          else
            gitsigns.nav_hunk(direction, { target = target })
          end
        end
      end

      map('n', ']c', nav_hunk('next', 'unstaged'), { desc = 'Next hunk' })
      map('n', '[c', nav_hunk('prev', 'unstaged'), { desc = 'Previous hunk' })
      map('n', ']s', nav_hunk('next', 'staged'), { desc = 'Next staged hunk' })
      map('n', '[s', nav_hunk('prev', 'staged'), { desc = 'Previous staged hunk' })

      -- Actions
      map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
      map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })
      map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Undo stage hunk' })

      map('v', '<leader>hs', function()
        gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { desc = 'Stage hunk' })

      map('v', '<leader>hr', function()
        gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { desc = 'Reset hunk' })

      map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
      map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
      map('n', '<leader>hU', gitsigns.reset_buffer_index, { desc = 'Unstage buffer' })

      map('n', '<leader>hb', function()
        gitsigns.blame_line({ full = true })
      end, { desc = 'Blame line' })

      map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff this' })

      map('n', '<leader>hD', function()
        gitsigns.diffthis('~')
      end, { desc = 'Diff this ~' })

      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle blame' })
      map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = 'Toggle word diff' })

      -- Text object
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'Select hunk' })
    end,
  },
}
