-- Main Hyprland config entry point. Keep module loading order explicit.
local config_root = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hypr_dir = config_root .. "/hypr"
local hl = hl

-- Monitor outputs and startup workspace placement.
dofile(hypr_dir .. "/monitors.lua")

-- Settings returns shared values used by other modules (for example gaps_in).
local settings = dofile(hypr_dir .. "/modules/settings.lua")(hl)

-- Register static rules and shortcuts before custom window behavior.
dofile(hypr_dir .. "/modules/bindings.lua")(hl)
local window_rules = dofile(hypr_dir .. "/modules/window-rules.lua")(hl)
local expose = dofile(hypr_dir .. "/modules/expose.lua")(hl)
dofile(hypr_dir .. "/modules/window-behavior.lua")(hl, settings, expose, window_rules)
