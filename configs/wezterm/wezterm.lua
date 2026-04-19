local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = 'Vs Code Dark+ (Gogh)'

local function scheme_choices()
    local schemes = wezterm.color.get_builtin_schemes()
    local choices = {}

    for name, _ in pairs(schemes) do
        table.insert(choices, { label = name, id = name })
    end

    table.sort(choices, function(a, b)
        return a.label < b.label
    end)

    return choices
end

local select_color_scheme = act.InputSelector {
    title = 'Select color scheme',
    fuzzy = true,
    choices = scheme_choices(),
    action = wezterm.action_callback(function(window, pane, id, label)
        if not id then
            return
        end

        local overrides = window:get_config_overrides() or {}
        overrides.color_scheme = id
        window:set_config_overrides(overrides)
    end),
}

config.font = wezterm.font_with_fallback {
    'AurulentSansM Nerd Font',
    'Sarasa Term SC Nerd',
}
config.font_size = 15
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
    {
        key = 'T',
        mods = 'CTRL|SHIFT',
        action = select_color_scheme,
    },
}

return config
