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

hl.config({
  general = {
    gaps_in          = 3,
    gaps_out         = 4,

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
    rounding       = 18,
    rounding_power = 3,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled        = true,
      color = "rgba(0, 0, 0, 0.45)",
      range = 28,
      render_power = 10,
    },

    blur = {
      enabled  = true,
      size     = 3,
      passes   = 3,
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

hl.animation({ leaf = "workspaces",    enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })

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

hl.bind("SUPER + T",         hl.dsp.window.float({ action = "toggle" }))       -- toggle float
hl.bind("SUPER + P",         hl.dsp.window.pseudo())                            -- toggle pseudo
hl.bind("SUPER + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))                      -- maximize
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())                                               -- fullscreen

--------------------------
---- FOCUS / CYCLE     ----
--------------------------

hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))
hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))

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
  match           = { class = "spotify|brave-browser|helium|Obsidian" },
  scroll_touchpad = 0.1,
})

--------------------------
---- APP LAUNCHERS     ----
--------------------------

hl.bind("SUPER + comma",  hl.dsp.exec_cmd("hypr-settings"))  -- settings
hl.bind("SUPER + Return", hl.dsp.exec_cmd("alacritty"))          -- terminal
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
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh ocr")) -- annotate
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
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("/home/veer/code/quarry/src-tauri/target/release/quarry-toggle"), { release = true })

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








































local expose = { active = false, saved = {} }

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


local function enter_expose()
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

  local top = 60
local L = best_layout(wins, mw, mh, top)
local cols, rows, pad, cw, ch = L.cols, L.rows, L.pad, L.cw, L.ch
  -- local pad, top = 40, 60
  -- local cols, rows = grid(#wins, mw, mh)
  -- local cw = (mw - pad * (cols + 1)) / cols
  -- local ch = (mh - top - pad * (rows + 1)) / rows

  -- sort top to bottom, split into rows, sort each row left to right
  table.sort(wins, function(a, b) return a.cy < b.cy end)
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

    -- local s = math.min(cw / it.sw, ch / it.sh, 1)
    local s = math.min(cw / it.sw, ch / it.sh, MAX_SCALE)
    local nw, nh = it.sw * s, it.sh * s
    local row_offset = (cols - it.rowcount) * (cw + pad) / 2
    local x = mx + pad + row_offset + it.col * (cw + pad) + (cw - nw) / 2
    local y = my + top + pad + it.row * (ch + pad) + (ch - nh) / 2

    hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, window = w }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = w }))
  end
  expose.active = true
  hl.dispatch(hl.dsp.submap("expose"))
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
  expose.saved, expose.active = {}, false
  hl.dispatch(hl.dsp.submap("reset"))
end



hl.bind("SUPER + G", function()
  local ok, err = pcall(function()
    if expose.active then exit_expose() else enter_expose() end
  end)
  if not ok then dbg("error: " .. err) end
end)

hl.define_submap("expose", function()
  hl.bind("escape", exit_expose)
  hl.bind("return", exit_expose)
  hl.bind("Tab", hl.dsp.window.cycle_next())
  hl.bind("SUPER + G", exit_expose)
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

-- per-workspace rules so windows opened later follow the mode
local function set_ws_rule(ws, mode)
  local r = ws_rules[ws.id]
  if not r then
    r = hl.window_rule({
      name  = "wsmode-float-" .. ws.id,
      match = { workspace = ws_selector(ws) },
      float = true,
    })
    r:set_enabled(false)
    ws_rules[ws.id] = r
  end
  r:set_enabled(mode == "float")
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
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
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
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = w }))
      end
    end
  end
end

hl.bind("SUPER + X", function()
  local ok, err = pcall(toggle_ws_float)
  if not ok then dbg("error: " .. err) end
end)
