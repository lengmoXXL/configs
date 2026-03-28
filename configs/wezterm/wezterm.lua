local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
    'AurulentSansM Nerd Font Mono',
    'Source Han Sans CN',
}
config.font_size = 11
config.window_decorations = 'RESIZE'

return config
