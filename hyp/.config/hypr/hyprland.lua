dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")

-- local hl = require("hyprland")
local hl = hl

------------------
---- MONITORS ----
------------------

hl.on("hyprland.start", function()
  -- hl.exec_cmd("hyprpanel")
  -- hl.exec_cmd("waybar")
  -- hl.exec_cmd("hyprpaper")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("systemd-run --user --scope kdeconnect-indicator")
  hl.exec_cmd("sleep 1; ~/.config/hypr/scripts/startup.sh")
end)

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("XCURSOR_SIZE", "20")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Autostart
-- hl.exec_once("dunst")
-- hl.exec_once("waybar")
-- hl.exec_once("hypridle")

hl.config({
  general = {
    gaps_in          = 1,
    gaps_out         = 0,

    border_size      = 1,

    col              = {
      active_border   = "rgba(200, 200, 200, 1)",
      inactive_border = "rgba(100, 100, 100, 1)",
    },

    resize_on_border = true,
    allow_tearing    = false,
    layout           = "master",
  },

  decoration = {
    rounding         = 4,
    rounding_power   = 2,

    active_opacity   = 1.0,
    inactive_opacity = 0.90,

    shadow           = {
      enabled        = false,
      range          = 20,
      render_power   = 4,
      color          = "rgba(00000088)",
      color_inactive = "rgba(00000044)",
    },

    blur             = {
      enabled  = true,
      size     = 3,
      passes   = 3,
      vibrancy = 0,
      special  = true,
    },
  },

  animations = { enabled = true },
})


hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = false, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slidefade 1%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slidefade 1%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slidefade 1%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidefade 1%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "easeInOutCubic" })

-- -- "Smart gaps" / "No gaps when only"
-- -- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
  dwindle = {
    preserve_split = true, -- You probably want this
  },
  master = {
    new_status = "master",
    mfact = 0.5
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
  scrolling = {
    fullscreen_on_one_column = true,
  },
})

----------------
----  MISC  ----
----------------

hl.config({
  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    disable_splash_rendering = true,
  },
})


---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout    = "us",
    kb_variant   = "",
    kb_model     = "",
    kb_options   = "",
    kb_rules     = "",

    follow_mouse = 1,

    sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

    touchpad     = {
      natural_scroll = true,
    },
  },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
  name        = "usb-optical-mouse-",
  sensitivity = -0.5,
  scroll_factor = 5,
})


----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
--------------------------      KEYS     -----------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------


hl.bind("SUPER + comma", hl.dsp.exec_cmd("hypr-settings")) -- settings

hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty")) -- terminal

hl.bind("SUPER + Q", hl.dsp.window.close())

hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("pkill quickshell; pkill -x hypridle; sleep 0.5; quickshell & hypridle & disown; sleep 0.5;")) -- restart shell

hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")) -- force logout

hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" })) 

hl.bind("SUPER + P", hl.dsp.window.pseudo())

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized"}))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())

hl.bind("SUPER + N", hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 2500")) -- nightlight

hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a")) -- color picker

hl.bind("Print",       hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh annotate"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output"))











hl.gesture({
    fingers = 4,
    direction = "pinchin",
    action = "cursor_zoom",
    zoom_level = 2,
    mode = "mult"
})

hl.gesture({
    fingers = 4,
    direction = "pinchout",
    action = "cursor_zoom",
    zoom_level = 0.5,
    mode = "mult"
})


-- hl.bind("SUPER + Equal", hl.dsp.exec_cmd("notify-send 'hello'"))
-- hl.bind("SUPER + Minus", hl.dsp.exec_cmd("notify-send 'hello'"))
--
-- the framework key / media key

hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("notify-send 'hello'"))
hl.bind("SUPER + XF86AudioMedia", hl.dsp.exec_cmd("~/.config/hypr/scripts/gaming-mode.sh"))


-- quarry

hl.bind("ALT + Space", hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"))

hl.bind("SUPER + V", hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry --with 'cp '"))

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"), { release = true })


-- Gestures 

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- hl.gesture({ fingers = 4, direction = "pinch", action = "cursorZoom", zoom_level = 1, mode = "live" })





----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------    WORKSPACES     -----------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- navigate
-- hl.bind("SUPER + H",     hl.dsp.focus({ direction = "left" }))
-- hl.bind("SUPER + J",     hl.dsp.focus({ direction = "down" }))
-- hl.bind("SUPER + K",     hl.dsp.focus({ direction = "up" }))
-- hl.bind("SUPER + L",     hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))
hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))

hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })

-- promote focused window to master
hl.bind("SUPER + Space", hl.dsp.layout("swapwithmaster"))

-- switch workspaces with super + [0-9]
-- move active window to a workspace with super + shift + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + Tab", function() hl.dispatch(hl.dsp.focus({ workspace = "e+1" })) end)
hl.bind("SUPER + SHIFT + Tab", function() hl.dispatch(hl.dsp.focus({ workspace = "e-1" })) end)
hl.bind("SUPER + CTRL + Tab", hl.dsp.focus({ workspace = "empty" }))

-- special workspace
hl.bind("SUPER + Grave", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + Grave", hl.dsp.window.move({ workspace = "special:magic" }))
hl.workspace_rule({ workspace = "special:magic", gaps_out = 38, gaps_in = 4 })

-- hl.workspace_rule({ workspace = "10", layout = "float" })
--
-- m/shift+m as named shortcuts for workspace 6
hl.bind("SUPER + M", hl.dsp.focus({ workspace = 6 }))
hl.bind("SUPER + SHIFT + M", hl.dsp.window.move({ workspace = 6 }))

hl.bind("SUPER + E", hl.dsp.focus({ workspace = 4 }))
hl.bind("SUPER + SHIFT + E", hl.dsp.window.move({ workspace = 4 }))

-- Alt+Tab to toggle back to last active workspace
hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Focus monitor (mirrors window cycle J/K, scoped up to monitor level)
hl.bind("SUPER + CTRL + J", hl.dsp.focus({ monitor = "+1" }))
hl.bind("SUPER + CTRL + K", hl.dsp.focus({ monitor = "-1" }))

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/mute-notify.sh @DEFAULT_AUDIO_SINK@"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/mute-notify.sh @DEFAULT_AUDIO_SOURCE@"), { locked = true, repeating = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh    6%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh  6%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

-- local suppressMaximizeRule = hl.window_rule({
--     -- Ignore maximize requests from all apps. You'll probably like this.
--     name  = "suppress-maximize-events",
--     match = { class = ".*" },
--     suppress_event = "maximize",
-- })
-- -- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})

hl.layer_rule({
  name  = "quickshell", -- status bar, notifications, osd, dock
  match = { namespace = "quickshell:.+" },
  blur  = true,
  ignore_alpha = 0.1,
  no_anim = true, -- so that it doesn't interefere with the native bounce morph animation
})

hl.window_rule({
  name        = "picture in picture",
  match       = { title = "^Picture-in-Picture$" },
  float       = true,
  pin         = true,
  border_size = 1,
})

hl.window_rule({
  name        = "quarry",
  match       = { class = "quarry" },
  float       = true,
  pin         = true,
  no_anim     = true,
  rounding   = 16
  -- animation   = "gnomed",
  -- dim_around   = true
})

hl.window_rule({
  name  = "live-captions",
  match = { class = ".*LiveCaptions.*" },
  float = true,
  pin   = true,
  rounding   = 16
})

hl.window_rule({
  name  = "preview",
  match = { class = ".*NautilusPreviewer.*" },
  float = true,
  rounding   = 16
})

hl.window_rule({
  name  = "satty",
  match = { class = ".*satty.*" },
  float = true,
  pin   = true,
  rounding   = 16
})

-- hl.window_rule({
--   name  = "obsidian",
--   match = { class = "obsidian" },
--   transparency = 0.1
-- })

-- change monitor to high resolution, the last argument is the scale factor
hl.monitor({ output = "", mode = "highres", position = "auto", scale = "2" })
-- unscale XWayland
hl.config({
  xwayland = {
    force_zero_scaling = true
  },

})
-- toolkit-specific scale
hl.env("GDK_SCALE", "2")
