return {
  'NeogitOrg/neogit',
  cmd = { 'Neogit', 'NeogitLogCurrent' },
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit' },
    { '<leader>gf', '<cmd>NeogitLogCurrent<cr>', desc = 'Neogit File History' },
    { '<leader>gl', '<cmd>Neogit log<cr>', desc = 'Neogit Log History' },
  },
  -- codediff.nvim 2.67.9+ 的 session_config 契约改为 panel/original/modified，neogit 上游集成还是旧的 mode/explorer_data 结构，更新后需重打补丁
  build = 'p=$HOME/.config/nvim/patches/neogit-codediff-session-config.patch; test -f "$p" && { git -C $HOME/.local/share/nvim/lazy/neogit apply --check -R "$p" 2>/dev/null || git -C $HOME/.local/share/nvim/lazy/neogit apply "$p" 2>/dev/null || echo "neogit codediff patch skipped (already adapted upstream?)"; }',
  opts = {
    integrations = {
      codediff = true,
    },
    diff_viewer = 'codediff',
  },
}
