hy3.exec_once("hyprpolkitagent")
hy3.exec_once("hyprsunset")

hyprland.monitor("eDP-1", "2256x1504@60", "0x0", "1.5")

hyprland.input({
    kb_layout = "us",
    follow_mouse = 1,
    touchpad = {
        natural_scroll = true,
        tap_to_click = true,
    },
})

hyprland.general({
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    resize_on_border = true,
    layout = "master",
})

hyprland.master({
    new_status = "slave",
    mfact = 0.55,
})

hyprland.decoration({
    rounding = 8,
    blur = {
        enabled = true,
        size = 6,
        passes = 2,
    },
})

hyprland.animations({
    enabled = true,
    bezier = { "easeOut", 0.05, 0.9, 0.1, 1.05 },
    animation = {
        { "windows",    1, 4, "easeOut" },
        { "workspaces", 1, 4, "easeOut" },
        { "fade",       1, 4, "default" },
    },
})

hyprland.misc({
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
})

local SUPER       = "SUPER"
local SUPER_SHIFT = "SUPER SHIFT"
local ALT         = "ALT"

hyprland.bind(SUPER, "Return", "exec",   "ghostty")
hyprland.bind(SUPER, "B",      "exec",   "firefox")
hyprland.bind(ALT,   "Return", "exec",   "/home/veer/code/quarry/src-tauri/target/release/quarry-toggle")

for i = 1, 9 do
    hyprland.bind(SUPER, tostring(i), "workspace", tostring(i))
end
hyprland.bind(SUPER, "0", "workspace", "10")

for i = 1, 9 do
    hyprland.bind(SUPER_SHIFT, tostring(i), "movetoworkspacesilent", tostring(i))
end
hyprland.bind(SUPER_SHIFT, "0", "movetoworkspacesilent", "10")

hyprland.bind(SUPER, "M", "workspace", "6")
hyprland.bind(SUPER_SHIFT, "M", "movetoworkspacesilent", "6")
hyprland.bind(ALT, "Tab", "workspace", "previous")
hyprland.bind(SUPER, "Space", "layoutmsg", "swapwithmaster master")

hyprland.bind(SUPER, "Q", "killactive")
hyprland.bind(SUPER, "F", "fullscreen", "0")
hyprland.bind(SUPER, "T", "togglefloating")

hyprland.bind(SUPER, "H", "movefocus", "l")
hyprland.bind(SUPER, "L", "movefocus", "r")
hyprland.bind(SUPER, "K", "movefocus", "u")
hyprland.bind(SUPER, "J", "movefocus", "d")

hyprland.bind(SUPER_SHIFT, "H", "movewindow", "l")
hyprland.bind(SUPER_SHIFT, "L", "movewindow", "r")
hyprland.bind(SUPER_SHIFT, "K", "movewindow", "u")
hyprland.bind(SUPER_SHIFT, "J", "movewindow", "d")
