local function close_codediff()
  local lifecycle = require('codediff.ui.lifecycle')
  local tabpage = nil

  for _, candidate in ipairs(vim.api.nvim_list_tabpages()) do
    if lifecycle.get_session(candidate) then
      tabpage = candidate
      break
    end
  end

  if not tabpage then
    return false
  end

  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd('tabnew')
  end

  if vim.api.nvim_tabpage_is_valid(tabpage) then
    vim.cmd(vim.api.nvim_tabpage_get_number(tabpage) .. 'tabclose')
  end

  return true
end

local function open_codediff(command)
  return function()
    close_codediff()
    vim.schedule(function()
      vim.cmd(command)
    end)
  end
end

local history_context_request = 0

local function show_history_commit_context(direction)
  return function()
    local lifecycle = require('codediff.ui.lifecycle')
    local history = lifecycle.get_explorer(vim.api.nvim_get_current_tabpage())
    if not history or vim.bo[0].filetype ~= 'codediff-history' then
      vim.notify('CodeDiff history panel is not focused', vim.log.levels.WARN)
      return
    end

    local node = history.tree:get_node()
    while node and node.data and node.data.type ~= 'commit' and node._parent_id do
      node = history.tree:get_node(node._parent_id)
    end

    if not node or not node.data or node.data.type ~= 'commit' then
      vim.notify('Select a commit in CodeDiff history first', vim.log.levels.WARN)
      return
    end

    local commit = node.data.hash
    history_context_request = history_context_request + 1
    local request = history_context_request
    local file_path = history.opts and history.opts.file_path or nil
    local git_opts = {
      no_merges = true,
      path = file_path,
    }

    local function open_range(range)
      local args = { 'history', range }
      if file_path and file_path ~= '' then
        args[#args + 1] = file_path
      end

      close_codediff()
      vim.api.nvim_cmd({ cmd = 'CodeDiff', args = args }, {})
    end

    local function commit_has_parent(hash)
      vim.fn.system({ 'git', '-C', history.git_root, 'rev-parse', '--verify', hash .. '^' })
      return vim.v.shell_error == 0
    end

    local git = require('codediff.core.git')
    if direction == 'up' then
      git.get_commit_list(commit .. '..HEAD', history.git_root, git_opts, vim.schedule_wrap(function(err, commits)
        if request ~= history_context_request then
          return
        end
        if err then
          vim.notify('Failed to get newer commits: ' .. err, vim.log.levels.ERROR)
          return
        end
        local first = math.max(1, #commits - 99)
        local newer_commit = commits[first] and commits[first].hash or commit
        local range = newer_commit
        if commit_has_parent(commit) then
          range = commit .. '^..' .. newer_commit
        end
        open_range(range)
      end))
      return
    end

    git.get_commit_list(commit, history.git_root, vim.tbl_extend('force', git_opts, { limit = 101 }), vim.schedule_wrap(function(err, commits)
      if request ~= history_context_request then
        return
      end
      if err then
        vim.notify('Failed to get older commits: ' .. err, vim.log.levels.ERROR)
        return
      end

      local oldest_commit = commits[#commits] and commits[#commits].hash or commit
      local range = commit
      if commit_has_parent(oldest_commit) then
        range = oldest_commit .. '^..' .. commit
      end
      open_range(range)
    end))
  end
end

return {
  'esmuellert/codediff.nvim',
  cmd = { 'CodeDiff' },
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('UserCodeDiffHistoryKeymaps', { clear = true }),
      pattern = 'codediff-history',
      callback = function(args)
        vim.keymap.set('n', '<leader>ju', show_history_commit_context('up'), {
          buffer = args.buf,
          desc = 'Show newer commit context',
          noremap = true,
          nowait = true,
          silent = true,
        })
        vim.keymap.set('n', '<leader>jd', show_history_commit_context('down'), {
          buffer = args.buf,
          desc = 'Show older commit context',
          noremap = true,
          nowait = true,
          silent = true,
        })
      end,
    })
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('UserCodeDiffExplorerKeymaps', { clear = true }),
      pattern = 'codediff-explorer',
      callback = function(args)
        vim.keymap.set('n', 'X', function()
          local lifecycle = require('codediff.ui.lifecycle')
          local explorer = lifecycle.get_explorer(vim.api.nvim_get_current_tabpage())
          if not explorer or not explorer.git_root then
            vim.notify('Discard all is only available in git mode', vim.log.levels.WARN)
            return
          end
          if explorer.base_revision or explorer.target_revision then
            vim.notify('Discard all is only available in CodeDiff status mode', vim.log.levels.WARN)
            return
          end

          local choice = vim.fn.confirm('Discard all working tree changes and untracked files?', '&Discard\n&Cancel', 2, 'Warning')
          vim.cmd("echo ''")
          if choice ~= 1 then
            return
          end

          local reset_output = vim.fn.system({ 'git', '-C', explorer.git_root, 'reset', '--hard', 'HEAD' })
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to discard tracked changes: ' .. vim.trim(reset_output), vim.log.levels.ERROR)
            return
          end

          local clean_output = vim.fn.system({ 'git', '-C', explorer.git_root, 'clean', '-fd' })
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to delete untracked files: ' .. vim.trim(clean_output), vim.log.levels.ERROR)
            return
          end

          require('codediff.ui.explorer').refresh(explorer)
          vim.notify('Discarded all CodeDiff changes', vim.log.levels.INFO)
        end, {
          buffer = args.buf,
          desc = 'Discard all changes',
          noremap = true,
          nowait = true,
          silent = true,
        })
      end,
    })
  end,
  keys = {
    { '<leader>jj', open_codediff('CodeDiff'), desc = 'Open CodeDiff' },
    { '<leader>jh', open_codediff('CodeDiff HEAD^ HEAD'), desc = 'Open CodeDiff HEAD' },
    { '<leader>jc', function()
      local clipboard = vim.trim(vim.fn.getreg('+'))
      local default = clipboard:match('^%x%x%x%x%x%x%x+%x*$') and clipboard or ''
      local commit = vim.trim(vim.fn.input('CodeDiff commit: ', default))
      if commit == '' then
        return
      end

      close_codediff()
      vim.schedule(function()
        vim.api.nvim_cmd({ cmd = 'CodeDiff', args = { commit .. '^', commit } }, {})
      end)
    end, desc = 'Open CodeDiff commit' },
    { '<leader>jH', open_codediff('CodeDiff history'), desc = 'Open CodeDiff history' },
  },
  opts = {
    keymaps = {
      view = {
        focus_explorer = '<leader>je',
      },
      explorer = {
        restore = 'x',
      },
    },
    explorer = {
      focus_on_select = true,
    },
  },
}
