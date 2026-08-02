dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")

-- local hl = require("hyprland")
local hl = hl

--------------------------
---- ENVIRONMENT       ----
--------------------------

hl.env("XCURSOR_THEME",                "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE",              "20")
hl.env("XCURSOR_SIZE",                 "20")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

--------------------------
---- MONITOR SCALE     ----
--------------------------

-- Default: high-res mode at 2× scale
hl.monitor({ output = "", mode = "highres", position = "auto", scale = "2" })

-- Toolkit-specific scale to match
hl.env("GDK_SCALE", "1")

--------------------------
---- XWAYLAND         ----
--------------------------

-- Unscale XWayland so apps aren't double-scaled
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})

--------------------------
---- GENERAL / BORDERS ----
--------------------------

hl.config({
  general = {
    gaps_in          = 2,
    gaps_out         = 2,

    border_size      = 1,

    col = {
      active_border   = "rgba(80, 80, 80, 1)",
      inactive_border = "rgba(50, 50, 50, 1)",
    },

    resize_on_border = true,
    allow_tearing    = false,
    layout           = "master",
  },
})

--------------------------
---- DECORATION        ----
--------------------------

hl.config({
  decoration = {
    rounding       = 12,
    rounding_power = 2,

    active_opacity   = 1.0,
    inactive_opacity = 0.90,

    shadow = {
      enabled        = false,
      range          = 20,
      render_power   = 4,
      color          = "rgba(00000088)",
      color_inactive = "rgba(00000044)",
    },

    blur = {
      enabled  = true,
      size     = 3,
      passes   = 2,
      vibrancy = 0,
      special  = true,
    },
  },
})

--------------------------
---- ANIMATIONS        ----
--------------------------

hl.config({ animations = { enabled = true } })

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71, dampening = 15})

-- Animation tree
hl.animation({ leaf = "global",     enabled = true, speed = 1, bezier = "default" })

hl.animation({ leaf = "windows",    enabled = true, speed = 4,  bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,  bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4,  bezier = "linear",       style = "popin 90%" })

hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1,  bezier = "quick" })

hl.animation({ leaf = "layers",     enabled = true, speed = 7,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",   enabled = true, speed = 8,  bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 8,  bezier = "linear",       style = "fade" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 11%" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 8, bezier = "easeInOutCubic" })

--------------------------
---- GESTURES          ----
--------------------------

-- 3-finger horizontal swipe → workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.gesture({ fingers = 4, direction = "pinch", action = "cursorZoom", zoom_level = 1, mode = "live" })

--------------------------
---- INPUT             ----
--------------------------

hl.config({
  input = {
    kb_layout  = "us",
    kb_variant = "",
    kb_model   = "",
    kb_options = "",
    kb_rules   = "",

    follow_mouse = 1,
    sensitivity  = 0,  -- -1.0 – 1.0, 0 means no modification

    touchpad = {
      natural_scroll = true,
      scroll_factor  = 0.3,
    },
  },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
  name          = "usb-optical-mouse-",
  sensitivity   = -0.5,
  scroll_factor = 1,
})

------------------
---- AUTOSTART ----
------------------

hl.on("hyprland.start", function()
  -- hl.exec_cmd("hyprpanel")
  -- hl.exec_cmd("waybar")
  -- hl.exec_cmd("hyprpaper")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemd-run --user --scope kdeconnect-indicator")
end)

--------------------------
---- LAYOUT CONFIG     ----
--------------------------

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/

hl.config({
  dwindle = {
    preserve_split = true,
  },
  master = {
    new_status = "slave",
    mfact      = 0.5,
  },
})

hl.config({
  scrolling = {
    fullscreen_on_one_column = true,
  },
})

hl.config({
  misc = {
    force_default_wallpaper  = -1,
    disable_hyprland_logo    = true,
    disable_splash_rendering = true,
  },
})

--------------------------
---- WINDOW STATE      ----
--------------------------

hl.bind("SUPER + T",         hl.dsp.window.float({ action = "toggle" }))       -- toggle float
hl.bind("SUPER + P",         hl.dsp.window.pseudo())                            -- toggle pseudo
hl.bind("SUPER + F",         hl.dsp.window.fullscreen({ mode = "maximized" })) -- maximize
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())                        -- fullscreen

--------------------------
---- FOCUS / CYCLE     ----
--------------------------

hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))
hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))

-- Promote focused window to master
hl.bind("SUPER + Space", hl.dsp.layout("swapwithmaster"))

--------------------------
---- RESIZE            ----
--------------------------

hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })

--------------------------
---- WORKSPACE NAV     ----
--------------------------

-- Switch workspaces / move window with SUPER + [0-9]
for i = 1, 10 do
  local key = i % 10  -- 10 maps to key 0
  hl.bind("SUPER + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + Tab",         function() hl.dispatch(hl.dsp.focus({ workspace = "e+1" })) end)
hl.bind("SUPER + SHIFT + Tab", function() hl.dispatch(hl.dsp.focus({ workspace = "e-1" })) end)
hl.bind("SUPER + CTRL + Tab",  hl.dsp.focus({ workspace = "empty" }))

-- Special workspace (scratchpad)
hl.bind("SUPER + Grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + Grave", hl.dsp.window.move({ workspace = "special:magic" }))
hl.workspace_rule({ workspace = "special:magic", gaps_out = 38, gaps_in = 4 })

-- Named workspace shortcuts (m → 6, e → 4)
hl.bind("SUPER + M",         hl.dsp.focus({ workspace = 6 }))
hl.bind("SUPER + SHIFT + M", hl.dsp.window.move({ workspace = 6 }))
hl.bind("SUPER + E",         hl.dsp.focus({ workspace = 4 }))
hl.bind("SUPER + SHIFT + E", hl.dsp.window.move({ workspace = 4 }))

-- Alt+Tab → last active workspace
hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Focus monitor
hl.bind("SUPER + CTRL + J", hl.dsp.focus({ monitor = "+1" }))
hl.bind("SUPER + CTRL + K", hl.dsp.focus({ monitor = "-1" }))

-- Scroll through workspaces with mouse wheel
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind("SUPER + mouse:272",         hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

--------------------------
---- WINDOW RULES      ----
--------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Fix dragging issues with XWayland
hl.window_rule({
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- Quickshell: status bar, notifications, osd, dock
hl.layer_rule({
  name         = "quickshell",
  match        = { namespace = "^quickshell:.*" },
  blur         = true,
  ignore_alpha = 0.2,
  no_anim      = true,  -- don't interfere with the native bounce morph animation
})

hl.window_rule({
  name        = "picture in picture",
  match       = { title = "^Picture-in-Picture$" },
  float       = true,
  pin         = true,
  border_size = 1,
})

hl.window_rule({
  name     = "quarry",
  match    = { class = "quarry" },
  float    = true,
  pin      = true,
  no_anim  = true,
  rounding = 16,
})

hl.window_rule({
  name     = "live-captions",
  match    = { class = ".*LiveCaptions.*" },
  float    = true,
  pin      = true,
  rounding = 16,
})

hl.window_rule({
  name     = "preview",
  match    = { class = ".*NautilusPreviewer.*" },
  float    = true,
  rounding = 16,
})

hl.window_rule({
  name     = "satty",
  match    = { class = ".*satty.*" },
  float    = true,
  pin      = true,
  rounding = 16,
})

hl.window_rule({
  name            = "chromium-scroll",
  match           = { class = "brave-browser|obsidian|helium" },
  scroll_touchpad = 0.2,
})

--------------------------
---- APP LAUNCHERS     ----
--------------------------

hl.bind("SUPER + comma",  hl.dsp.exec_cmd("hypr-settings"))  -- settings
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))          -- terminal
hl.bind("SUPER + B",      hl.dsp.exec_cmd("xdg-open https://"))  -- browser

--------------------------
---- SYSTEM ACTIONS    ----
--------------------------

hl.bind("SUPER + Q",         hl.dsp.window.close())  -- close window
hl.bind("SUPER + L",         hl.dsp.exec_cmd("loginctl lock-session"))  -- lock
hl.bind("SUPER + N",         hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 2500"))  -- nightlight
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("pkill quickshell; pkill -x hypridle; sleep 0.5; hyprctl reload; quickshell & hypridle & disown; sleep 0.5;"))  -- restart shell

hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))  -- force logout

--------------------------
---- UTILITIES         ----
--------------------------

hl.bind("SUPER + G", hl.dsp.exec_cmd("~/scripts/gamemode.sh")) --gaming mode

hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))  -- color picker

-- Screenshots
hl.bind("Print",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))   -- region
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh annotate")) -- annotate
hl.bind("SUPER + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output"))   -- output

-- Framework media key
hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("qs ipc call ripple triggerColor '#ff6b6b'"))

--------------------------
---- QUARRY            ----
--------------------------

hl.bind("ALT + Space",     hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"))
hl.bind("SUPER + V",       hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry --with 'cp '"))
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"), { release = true })

--------------------------
---- MEDIA KEYS        ----
--------------------------

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%+"),                   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%-"),                   { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.config/hypr/scripts/mute-notify.sh @DEFAULT_AUDIO_SINK@"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("~/.config/hypr/scripts/mute-notify.sh @DEFAULT_AUDIO_SOURCE@"), { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh --instant 6%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh --instant 6%-"), { locked = true, repeating = true })

-- Playback (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
