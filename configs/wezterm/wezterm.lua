local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = 'GitHub Dark'

config.font = wezterm.font_with_fallback {
    'AurulentSansM Nerd Font',
    'Sarasa Term SC Nerd',
}
config.font_size = 14
config.window_decorations = 'RESIZE'

config.default_prog = { 'ssh', 'admin@47.95.238.149' }

config.launch_menu = {
    {
        label = 'Local Shell',
        args = { os.getenv 'SHELL' or '/bin/zsh' },
    },
    {
        label = 'Remote Ecs',
        args = { 'ssh', 'admin@47.95.238.149' },
    },
}

config.keys = {
    {
        key = 'd',
        mods = 'SUPER',
        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'd',
        mods = 'SUPER|SHIFT',
        action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
        key = 's',
        mods = 'CTRL|SHIFT',
        action = act.PaneSelect {
            mode = 'SwapWithActive',
        },
    },
}

return config
