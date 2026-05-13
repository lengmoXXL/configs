local M = {}

function M.setup()
  vim.filetype.add({
    pattern = {
      ['.*'] = {
        function(path)
          path = vim.fs.normalize(path)
          local git_marker = vim.fs.find('.git', {
            path = vim.fs.dirname(path),
            upward = true,
          })[1]
          if not git_marker then
            return
          end

          local root = vim.fs.dirname(git_marker)
          local git_url = vim.fn.systemlist({ 'git', '-C', root, 'config', '--get', 'remote.origin.url' })[1]
          if vim.v.shell_error ~= 0 or not git_url or git_url == '' then
            return
          end

          local config_path = vim.fn.stdpath('data') .. '/filetypes.json'
          local ok, lines = pcall(vim.fn.readfile, config_path)
          if not ok then
            return
          end

          local decode_ok, config = pcall(vim.json.decode, table.concat(lines, '\n'))
          if not decode_ok or type(config) ~= 'table' then
            return
          end

          local projects = type(config.projects) == 'table' and config.projects or config
          local files = projects[git_url]
          if type(files) ~= 'table' then
            return
          end

          for file, filetype in pairs(files) do
            if type(file) == 'string' and type(filetype) == 'string' then
              if path == vim.fs.normalize(root .. '/' .. file) then
                return filetype
              end
            end
          end
        end,
        { priority = math.huge },
      },
    },
  })
end

return M
