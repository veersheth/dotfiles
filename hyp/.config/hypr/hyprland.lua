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
-- hl.env("GDK_SCALE", "1")

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

local GAPS_IN = 2

hl.config({
  general = {
    gaps_in          = GAPS_IN,
    gaps_out         = 0,

    border_size      = 1,

    col = {
      active_border   = "rgba(130, 130, 130, 1)",
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
    rounding       = 17,
    rounding_power = 2.5,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      color = "rgba(0, 0, 0, 0.25)",
      range = 20,
      render_power = 3,
    },

    blur = {
      enabled  = true,
      size     = 4,
      passes   = 2,
      vibrancy = 0,
      special  = false,
    },

    -- motion_blur = {
    --   enabled = true;
    --   samples = 20;
    -- },

    -- wobble = {
    --   enabled = true,
    -- },

  },
})

-------------------------
-----  SMART GAPS -------
-------------------------

-- hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, rounding = 0 })

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
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3,  bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,  bezier = "linear",       style = "slide" })

hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1,  bezier = "quick" })

hl.animation({ leaf = "layers",     enabled = true, speed = 7,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",   enabled = true, speed = 7,  bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 7,  bezier = "linear",       style = "fade" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 2, bezier = "easeOutQuint", style = "slide" })
-- hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
-- hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })

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

    float_switch_override_focus = 0,   -- floating windows only raise on click

    touchpad = {
      natural_scroll = true,
      scroll_factor  = 0.40,
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
    mfact      = 0.50,
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

-- hl.bind("SUPER + T",         hl.dsp.window.float({ action = "toggle" }))       -- toggle float
hl.bind("SUPER + P",         hl.dsp.window.pseudo())                            -- toggle pseudo
-- hl.bind("SUPER + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))                      -- maximize
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())                                               -- fullscreen

--------------------------
---- FOCUS / CYCLE     ----
--------------------------

-- SUPER + J / K are defined further down (switcher_step), after the expose code.
-- hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))
-- hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))

-- Promote focused window to master
hl.bind("SUPER + Space",       hl.dsp.layout("swapwithmaster"))
-- Toggle master orientation: horizontal (left) ↔ vertical (top)
hl.bind("SUPER + SHIFT + Space", hl.dsp.layout("orientationcycle left top"))

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

-- Named workspace shortcuts
hl.bind("SUPER + M",         hl.dsp.focus({ workspace = "name:music" }))
hl.bind("SUPER + SHIFT + M", hl.dsp.window.move({ workspace = "name:music" }))
hl.bind("SUPER + N",         hl.dsp.focus({ workspace = "name:notes" }))
hl.bind("SUPER + SHIFT + N", hl.dsp.window.move({ workspace = "name:notes" }))
hl.bind("SUPER + I",         hl.dsp.focus({ workspace = "name:i" }))
hl.bind("SUPER + SHIFT + I", hl.dsp.window.move({ workspace = "name:i" }))
hl.window_rule({ match = { workspace = "name:i" }, float = true })
hl.bind("SUPER + O",         hl.dsp.focus({ workspace = "name:o" }))
hl.bind("SUPER + SHIFT + O", hl.dsp.window.move({ workspace = "name:o" }))
hl.bind("SUPER + E",         hl.dsp.focus({ workspace = "name:files" }))
hl.bind("SUPER + SHIFT + E", hl.dsp.window.move({ workspace = "name:files" }))

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

-- Start every new window floating; SUPER + X can switch a whole workspace
-- back to tiled mode.
hl.window_rule({
  name  = "default-floating",
  match = { class = ".*" },
  float = true,
})

hl.window_rule({
  name           = "firefox-persistent-size",
  match          = { class = "^firefox$" },
  persistent_size = true,
})

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
  -- blur         = true,
  ignore_alpha = 0.2,
  no_anim      = true,  -- don't interfere with the native bounce morph animation
})

hl.window_rule({
  name        = "picture in picture",
  match       = { title = "Picture-in-Picture" },
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
})

hl.window_rule({
  name     = "live-captions",
  match    = { class = ".*LiveCaptions.*" },
  float    = true,
  pin      = true,
})

hl.window_rule({
  name     = "preview",
  match    = { class = ".*NautilusPreviewer.*" },
  float    = true,
})

hl.window_rule({
  name     = "satty",
  match    = { class = ".*satty.*" },
  float    = true,
  pin      = true,
})

hl.window_rule({
  name            = "chromium-scroll",
  match           = { class = "spotify|brave-browser|helium|md.obsidian.Obsidian" },
  scroll_touchpad = 0.1,
})

--------------------------
---- APP LAUNCHERS     ----
--------------------------

hl.bind("SUPER + SHIFT + d", hl.dsp.exec_cmd("if [ \"$(gsettings get org.gnome.desktop.interface color-scheme)\" = \"'prefer-dark'\" ]; then gsettings set org.gnome.desktop.interface color-scheme prefer-light; else gsettings set org.gnome.desktop.interface color-scheme prefer-dark; fi"))
hl.bind("SUPER + comma",  hl.dsp.exec_cmd("hypr-settings"))  -- settings
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))          -- terminal
hl.bind("SUPER + B",      hl.dsp.exec_cmd("xdg-open https://"))  -- browser

--------------------------
---- SYSTEM ACTIONS    ----
--------------------------

hl.bind("SUPER + Q",         hl.dsp.window.close())  -- close window
hl.bind("SUPER + L",         hl.dsp.exec_cmd("loginctl lock-session"))  -- lock
hl.bind("SUPER + XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight"))  -- nightlight
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("pkill quickshell; pkill -x hypridle; sleep 0.5; hyprctl reload; quickshell & hypridle & disown; sleep 0.5;"))  -- restart shell

hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))  -- force logout

--------------------------
---- UTILITIES         ----
--------------------------

hl.bind("SUPER + CTRL + G", hl.dsp.exec_cmd("~/scripts/gamemode")) --gaming mode

hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))  -- color picker

-- Screenshots
hl.bind("Print",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))   -- region
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh annotate")) -- annotate
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh ocr")) -- ocr
hl.bind("SUPER + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output"))   -- output
hl.bind("ALT + Print",  hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh lens"))     -- google lens

-- Framework media key
hl.bind("SUPER + XF86AudioMedia", hl.dsp.exec_cmd("kitty -e nixx --hold"))
hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("qs ipc call flash triggerWith '#233b82' 600"))

--------------------------
---- QUARRY            ----
--------------------------

hl.bind("ALT + Space",     hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"))
hl.bind("SUPER + V",       hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry --with 'cp '"))
-- SUPER release → quarry toggle is defined further down, next to the J/K binds.

--------------------------
---- MEDIA KEYS        ----
--------------------------

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%+"),                   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh 5%-"),                   { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh --mute"),                              { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh --mute @DEFAULT_AUDIO_SOURCE@"), { locked = true })

-- Brightness

hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightess.sh up"),
    { repeating = true, locked = true }
)

hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightess.sh down"),
    { repeating = true, locked = true }
)

-- hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%;  qs ipc call osd brightness"), { repeating = true, locked = true })
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-;  qs ipc call osd brightness"), { repeating = true, locked = true })

-- Playback (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------------------------------------
---- EXPOSE                                  ----
------------------------------------------------

local expose = { active = false, switcher = false, saved = {} }

local function dbg(msg)
  -- msg = tostring(msg):gsub("'", "")
  -- hl.exec_cmd("notify-send expose '" .. msg .. "'")
end

local function xy(t) return t.x or t[1], t.y or t[2] end

-- local function grid(n, mw, mh)
--   local cols = math.ceil(math.sqrt(n * mw / mh))
--   return cols, math.ceil(n / cols)
-- end

local MAX_SCALE = 1.0   -- 1.0 = never enlarge past original size

local function layout_for(wins, mw, mh, top, cols)
  local n    = #wins
  local rows = math.ceil(n / cols)
  local pad  = math.max(10, math.min(40, 160 / n))
  local cw   = (mw - pad * (cols + 1)) / cols
  local ch   = (mh - top - pad * (rows + 1)) / rows
  local score = 0
  for _, it in ipairs(wins) do
    score = score + math.min(cw / it.sw, ch / it.sh, MAX_SCALE)
  end
  return { cols = cols, rows = rows, pad = pad, cw = cw, ch = ch, score = score }
end

local function best_layout(wins, mw, mh, top)
  local best
  for cols = 1, #wins do
    local l = layout_for(wins, mw, mh, top, cols)
    if l.cw > 0 and l.ch > 0 and (not best or l.score > best.score + 1e-6) then
      best = l
    end
  end
  return best or layout_for(wins, mw, mh, top, math.ceil(math.sqrt(#wins)))
end

local function wkey(w)
  return tostring(w.address or w)
end

-- lay out a list of window items in the expose grid and record their
-- original geometry in expose.saved
local function place_windows(wins)
  local mon = hl.get_monitors()[1]
  local sc  = mon.scale or 1
  local mw, mh = mon.width / sc, mon.height / sc
  local mx, my = mon.x or 0, mon.y or 0

  local top = 60
  local L = best_layout(wins, mw, mh, top)
  local cols, rows, pad, cw, ch = L.cols, L.rows, L.pad, L.cw, L.ch

  -- sort top to bottom, split into rows, sort each row left to right
  table.sort(wins, function(a, b)
    local acy, bcy = math.floor(a.cy + 0.5), math.floor(b.cy + 0.5)
    if acy ~= bcy then return acy < bcy end
    local acx, bcx = math.floor(a.cx + 0.5), math.floor(b.cx + 0.5)
    if acx ~= bcx then return acx < bcx end
    return wkey(a.win) < wkey(b.win)
  end)

  local ordered = {}
  for r = 0, rows - 1 do
    local row = {}
    for c = 1, cols do
      local item = wins[r * cols + c]
      if item then table.insert(row, item) end
    end
    table.sort(row, function(a, b) return a.cx < b.cx end)
    for c, item in ipairs(row) do
      item.col, item.row, item.rowcount = c - 1, r, #row
      table.insert(ordered, item)
    end
  end

  expose.saved = {}
  for _, it in ipairs(ordered) do
    local w = it.win
    table.insert(expose.saved, {
      win = w, x = it.ax, y = it.ay, w = it.sw, h = it.sh, tiled = it.tiled,
    })

    local s = math.min(cw / it.sw, ch / it.sh, MAX_SCALE)
    local nw, nh = it.sw * s, it.sh * s
    local row_offset = (cols - it.rowcount) * (cw + pad) / 2
    local x = mx + pad + row_offset + it.col * (cw + pad) + (cw - nw) / 2
    local y = my + top + pad + it.row * (ch + pad) + (ch - nh) / 2

    hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, window = w }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = w }))
  end
end

local function enter_expose(no_submap)
  local ws  = hl.get_active_workspace()
  local mon = hl.get_monitors()[1]
  local sc  = mon.scale or 1
  local mw, mh = mon.width / sc, mon.height / sc
  local mx, my = mon.x or 0, mon.y or 0

  -- collect every window on this workspace, floating or tiled,
  -- capturing geometry BEFORE any floating happens
  local wins = {}
  for _, w in ipairs(hl.get_windows()) do
    if w.workspace and w.workspace.id == ws.id then
      local ax, ay = xy(w.at)
      local sw, sh = xy(w.size)
      table.insert(wins, {
        win = w, ax = ax, ay = ay, sw = sw, sh = sh,
        cx = ax + sw / 2, cy = ay + sh / 2,
        tiled = not w.floating,
      })
    end
  end
  if #wins == 0 then return end

  -- float the tiled ones so they can be moved and resized
  for _, it in ipairs(wins) do
    if it.tiled then
      hl.dispatch(hl.dsp.window.float({ action = "enable", window = it.win }))
    end
  end

  place_windows(wins)
  expose.active = true
  if not no_submap then
    hl.dispatch(hl.dsp.submap("expose"))
  end
end

local function exit_expose()
  -- floating windows go back to their exact spots
  for _, s in ipairs(expose.saved) do
    if not s.tiled then
      hl.dispatch(hl.dsp.window.resize({ x = s.w, y = s.h, window = s.win }))
      hl.dispatch(hl.dsp.window.move({ x = s.x, y = s.y, window = s.win }))
    end
  end

  -- tiled windows get re-tiled in their original layout order
  -- (left to right, then top to bottom; this matches master orientation "left")
  local tiled = {}
  for _, s in ipairs(expose.saved) do
    if s.tiled then table.insert(tiled, s) end
  end
  table.sort(tiled, function(a, b)
    if a.x ~= b.x then return a.x < b.x end
    return a.y < b.y
  end)
  for _, s in ipairs(tiled) do
    hl.dispatch(hl.dsp.window.float({ action = "disable", window = s.win }))
  end

  hl.dispatch(hl.dsp.window.bring_to_top())
  expose.saved, expose.active, expose.switcher = {}, false, false
  hl.dispatch(hl.dsp.submap("reset"))
end

-- SUPER+Q inside expose: close the focused window and re-flow the grid
local function close_in_expose()
  local w = hl.get_active_window()
  if not w then return end
  local k = wkey(w)
  hl.dispatch(hl.dsp.window.close())

  local wins = {}
  for _, sv in ipairs(expose.saved) do
    if wkey(sv.win) ~= k then
      table.insert(wins, {
        win = sv.win, ax = sv.x, ay = sv.y, sw = sv.w, sh = sv.h,
        cx = sv.x + sv.w / 2, cy = sv.y + sv.h / 2,
        tiled = sv.tiled,
      })
    end
  end

  if #wins == 0 then
    expose.saved = {}
    exit_expose()
    return
  end
  place_windows(wins)
end

local function toggle_expose()
  local ok, err = pcall(function()
    if expose.active then exit_expose() else enter_expose() end
  end)
  if not ok then dbg("error: " .. err) end
end

hl.bind("SUPER + D", toggle_expose)
hl.bind("SUPER + SUPER_L", toggle_expose, { release = true })

-- SUPER+J/K: when the focused window is floating, cycle focus through windows
-- and raise each one to the front (no expose). Tiled windows keep the normal
-- master cyclenext/cycleprev behaviour.
local function switcher_step(dir)
  local ok, err = pcall(function()
    local w = hl.get_active_window()
    if expose.active or (w and w.floating) then
      -- floating: cycle focus and raise the newly focused window
      if dir > 0 then
        hl.dispatch(hl.dsp.window.cycle_next())
      else
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
      end
      if not expose.active then
        hl.dispatch(hl.dsp.window.bring_to_top())
      end
    else
      -- tiled: normal master behaviour
      hl.dispatch(hl.dsp.layout(dir > 0 and "cyclenext" or "cycleprev"))
    end
  end)
  if not ok then dbg("error: " .. err) end
end

-- global binds (work from normal mode)
hl.bind("SUPER + J", function() switcher_step(1)  end)
hl.bind("SUPER + K", function() switcher_step(-1) end)

hl.define_submap("expose", function()
  hl.bind("escape", exit_expose)
  hl.bind("return", exit_expose)
  hl.bind("Tab", hl.dsp.window.cycle_next())
  hl.bind("SUPER + D", exit_expose)
  hl.bind("SUPER + SUPER_L", exit_expose, { release = true })
  hl.bind("SUPER + Q", function()
    local ok, err = pcall(close_in_expose)
    if not ok then dbg("error: " .. err) end
  end)

  -- keep cycling while in the submap (global binds don't fire here)
  hl.bind("SUPER + J", function() switcher_step(1)  end)
  hl.bind("SUPER + K", function() switcher_step(-1) end)

  -- left click: pick the window under the cursor and close expose
  hl.bind("mouse:272", function()
    local ok, err = pcall(exit_expose)
    if not ok then dbg("error: " .. err) end
  end)
end)

hl.gesture({
  fingers   = 3,
  direction = "up",
  action    = function()
    local ok, err = pcall(function()
      if not expose.active then enter_expose() end
    end)
    if not ok then dbg("error: " .. err) end
  end,
})

-- 3-finger swipe down: close it
hl.gesture({
  fingers   = 3,
  direction = "down",
  action    = function()
    local ok, err = pcall(function()
      if expose.active then exit_expose() end
    end)
    if not ok then dbg("error: " .. err) end
  end,
})

------------------------------------------------
---- Remember each window's last floating geometry ----
------------------------------------------------

local float_mem = {}   -- [window key] = { x, y, w, h }

local function fkey(w) return tostring(w.address or w) end

-- call while the window is still floating, before tiling it
local function remember_float(w)
  if not w.floating then return end
  local x, y = xy(w.at)
  local sw, sh = xy(w.size)
  float_mem[fkey(w)] = { x = x, y = y, w = sw, h = sh }
end

local function float_window(w)
  hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
  local m = float_mem[fkey(w)]
  if m then
    hl.dispatch(hl.dsp.window.resize({ x = m.w, y = m.h, window = w }))
    hl.dispatch(hl.dsp.window.move({   x = m.x, y = m.y, window = w }))
  end
end

local function tile_window(w)
  remember_float(w)
  hl.dispatch(hl.dsp.window.float({ action = "disable", window = w }))
end

hl.bind("SUPER + T", function()
  if expose.active then return end
  local w = hl.get_active_window()
  if not w then return end
  if w.floating then tile_window(w) else float_window(w) end
end)

------------------------------------------------
---- SUPER + X: toggle workspace float/tile ----
------------------------------------------------

local ws_mode  = {}   -- [workspace id] = "float" | "tile"
local ws_rules = {}   -- [workspace id] = { float = rule, tile = rule }

local function ws_selector(ws)
  if ws.name and tostring(ws.id) ~= ws.name then
    return "name:" .. ws.name
  end
  return tostring(ws.id)
end

-- Per-workspace rules override the default for windows opened later.
local function set_ws_rule(ws, mode)
  local rules = ws_rules[ws.id]
  if not rules then
    local match = { workspace = ws_selector(ws) }
    rules = {
      float = hl.window_rule({
        name  = "wsmode-float-" .. ws.id,
        match = match,
        float = true,
      }),
      tile = hl.window_rule({
        name  = "wsmode-tile-" .. ws.id,
        match = match,
        tile  = true,
      }),
    }
    rules.float:set_enabled(false)
    rules.tile:set_enabled(false)
    ws_rules[ws.id] = rules
  end
  rules.float:set_enabled(mode == "float")
  rules.tile:set_enabled(mode == "tile")
end

local function toggle_ws_float()
  if expose.active then return end

  local ws = hl.get_active_workspace()
  if not ws then return end

  local wins, all_floating = {}, true
  for _, w in ipairs(hl.get_windows()) do
    if w.workspace and w.workspace.id == ws.id and not w.pinned then
      table.insert(wins, w)
      if not w.floating then all_floating = false end
    end
  end

  local to_float
  if #wins == 0 then
    to_float = ws_mode[ws.id] ~= "float"      -- empty workspace: just flip the mode
  else
    to_float = not all_floating               -- anything tiled -> float all; all floating -> tile all
  end

  ws_mode[ws.id] = to_float and "float" or "tile"
  set_ws_rule(ws, ws_mode[ws.id])

  if to_float then
    for _, w in ipairs(wins) do
      if not w.floating then
        float_window(w)
      end
    end
  else
    -- re-tile left to right, then top to bottom, so master/stack order is sensible
    table.sort(wins, function(a, b)
      local ax, ay = xy(a.at)
      local bx, by = xy(b.at)
      if ax ~= bx then return ax < bx end
      return ay < by
    end)
    for _, w in ipairs(wins) do
      if w.floating then
        tile_window(w)
      end
    end
  end
end

hl.bind("SUPER + X", function()
  local ok, err = pcall(toggle_ws_float)
  if not ok then dbg("error: " .. err) end
end)

------------------------------------------------
---- SUPER + F: pseudo-maximize when floating ----
------------------------------------------------

local PMAX_MARGIN = GAPS_IN -- keep floating maximize aligned with the tiled gap
local pmax_saved  = {}      -- [window key] = { x, y, w, h }

local function win_key(w)
  return w.address or tostring(w)
end

local function pseudo_maximize(w)
  local mon = hl.get_monitors()[1]            -- same lookup your expose code uses
  local sc  = mon.scale or 1
  local mw, mh = mon.width / sc, mon.height / sc
  local mx, my = mon.x or 0, mon.y or 0

  -- manual reserved space (logical px), used if the monitor reports none
  local BAR_TOP, BAR_BOTTOM, BAR_LEFT, BAR_RIGHT = 40, 0, 0, 0

  -- Hyprland order is {left, top, right, bottom}
  local rl, rt, rr, rb = 0, 0, 0, 0
  if type(mon.reserved) == "table" then
    rl, rt = mon.reserved[1] or 0, mon.reserved[2] or 0
    rr, rb = mon.reserved[3] or 0, mon.reserved[4] or 0
  end

  -- fall back to the manual values when nothing is reported
  if rl + rt + rr + rb == 0 then
    rl, rt, rr, rb = BAR_LEFT, BAR_TOP, BAR_RIGHT, BAR_BOTTOM
  end

  local key = win_key(w)
  local ax, ay = xy(w.at)
  local sw, sh = xy(w.size)

  local nx = mx + rl + PMAX_MARGIN
  local ny = my + rt + PMAX_MARGIN
  local nw = mw - rl - rr - PMAX_MARGIN * 2
  local nh = mh - rt - rb - PMAX_MARGIN * 2

  local saved = pmax_saved[key]
  local already = saved
    and math.abs(ax - nx) < 3 and math.abs(ay - ny) < 3
    and math.abs(sw - nw) < 3 and math.abs(sh - nh) < 3

  if already then
    -- second press: restore the previous geometry
    hl.dispatch(hl.dsp.window.resize({ x = saved.w, y = saved.h, window = w }))
    hl.dispatch(hl.dsp.window.move({   x = saved.x, y = saved.y, window = w }))
    pmax_saved[key] = nil
  else
    pmax_saved[key] = { x = ax, y = ay, w = sw, h = sh }
    hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, window = w }))
    hl.dispatch(hl.dsp.window.move({   x = nx, y = ny, window = w }))
  end
end

hl.bind("SUPER + F", function()
  if expose.active then return end

  local w = hl.get_active_window()
  if w and w.floating then
    local ok, err = pcall(pseudo_maximize, w)
    if not ok then dbg("error: " .. err) end
  else
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
  end
end)
