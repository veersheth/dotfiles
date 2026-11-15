-- Hyprland configuration. Monitor placement remains machine-specific.
local hl = hl
local config_root = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
dofile(config_root .. "/hypr/monitors.lua")

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
    rounding       = 6,
    rounding_power = 2.5,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      color = "rgba(0, 0, 0, 0.25)",
      range = 14,
      render_power = 3,
    },

    blur = {
      enabled  = false,
      size     = 5,
      passes   = 5,
      vibrancy = 0,
      special  = false,
      -- variant = 'kawase',
      -- variant = 'acrylic',
      -- variant = 'aurora',
      -- variant = 'drops',
      -- variant = 'fluid_jar',
      -- variant = 'frost',
      -- variant = 'haze',
      -- variant = 'heat_shimmer',
      -- variant = 'prism',
      -- variant = 'ripple',
      -- variant = 'water',
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
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3,  bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,  bezier = "linear",       style = "slide" })

hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1,  bezier = "quick" })

hl.animation({ leaf = "layers",     enabled = true, speed = 7,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",   enabled = true, speed = 7,  bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 7,  bezier = "linear",       style = "fade" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 2, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefadevert 11%" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 8, bezier = "easeInOutCubic" })

--------------------------
---- GESTURES          ----
--------------------------

-- 3-finger horizontal swipe → workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.gesture({ fingers = 4, direction = "pinch", action = "cursorZoom", zoom_level = 1, mode = "live" })

local hypr_expose = dofile(config_root .. "/hypr/modules/expose.lua")(hl)
hl.gesture({ fingers = 3, direction = "up", action = hypr_expose.open })
hl.gesture({ fingers = 3, direction = "down", action = hypr_expose.close })

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

-- Daily-use shortcuts.
--------------------------
---- WINDOW STATE      ----
--------------------------

hl.bind("SUPER + P",         hl.dsp.window.pseudo())                            -- toggle pseudo
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())                                               -- fullscreen

--------------------------
---- FOCUS / CYCLE     ----
--------------------------

-- Promote focused window to master
hl.bind("SUPER + Space",       hl.dsp.layout("swapwithmaster"))
-- Toggle master orientation: horizontal (left) ↔ vertical (top)
hl.bind("SUPER + SHIFT + Space", hl.dsp.layout("orientationcycle left top"))

-- Cycle floating windows by focus and z-order; cycle tiled windows in the layout.
local function cycle_window(forward)
  local ok, err = pcall(function()
    local w = hl.get_active_window()
    if w and w.floating then
      if forward then
        hl.dispatch(hl.dsp.window.cycle_next())
      else
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
      end
      hl.dispatch(hl.dsp.window.bring_to_top())
    else
      hl.dispatch(hl.dsp.layout(forward and "cyclenext" or "cycleprev"))
    end
  end)
  if not ok then print("[hyprland window cycle] " .. tostring(err)) end
end

hl.bind("SUPER + J", function() cycle_window(true) end)
hl.bind("SUPER + K", function() cycle_window(false) end)

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
hl.bind("SUPER + N",         hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + SHIFT + N", hl.dsp.window.move({ workspace = "3" }))
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
---- APP LAUNCHERS     ----
--------------------------

hl.bind("SUPER + SHIFT + d", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-color-scheme.sh"))
hl.bind("SUPER + comma",  hl.dsp.exec_cmd("hypr-settings"))  -- settings
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))          -- terminal
hl.bind("SUPER + B",      hl.dsp.exec_cmd("xdg-open https://"))  -- browser

--------------------------
---- SYSTEM ACTIONS    ----
--------------------------

hl.bind("SUPER + Q",         hl.dsp.window.close())  -- close window
hl.bind("SUPER + L",         hl.dsp.exec_cmd("loginctl lock-session"))  -- lock
hl.bind("SUPER + D",         hl.dsp.exec_cmd("qs ipc call expose toggle"))
hl.bind("SUPER + SUPER_L",   hypr_expose.toggle, { release = true })
hl.bind("SUPER + XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight"))  -- nightlight off / 6000 K
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/restart-shell.sh"))  -- restart shell

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
-- hl.bind("SUPER + XF86AudioMedia", hl.dsp.exec_cmd("kitty -e nixx --hold"))
hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("qs ipc call expose toggle"))
hl.bind("SUPER + XF86AudioMedia", hl.dsp.exec_cmd("qs ipc call flash triggerWith '#233b82' 600"))

--------------------------
---- QUARRY            ----
--------------------------

local quarry_bin = os.getenv("QUARRY_BIN_DIR") or (os.getenv("HOME") .. "/code/quarry/src-tauri/target/release")
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end
hl.bind("ALT + Space", hl.dsp.exec_cmd(shell_quote(quarry_bin .. "/quarry-toggle")))
hl.bind("SUPER + V",   hl.dsp.exec_cmd(shell_quote(quarry_bin .. "/quarry") .. " --with 'cp '"))

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
    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh up"),
    { repeating = true, locked = true }
)

hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh down"),
    { repeating = true, locked = true }
)

-- Playback (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Static window and layer rules.
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
  name            = "firefox-persistent-size",
  match           = { class = "^firefox$" },
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
  match           = { class = "spotify|brave-browser|helium|md.obsidian.Obsidian|learnharness" },
  scroll_touchpad = 0.1,
})

-- Workspace mode is a default, not an override for utility windows.
-- Keep both new-window matching and existing-window filtering here.
local window_rules = {
  workspace_match = function(workspace)
    return {
      workspace = workspace,
      class = "negative:(quarry|.*LiveCaptions.*|.*NautilusPreviewer.*|.*satty.*)",
      title = "negative:Picture-in-Picture",
    }
  end,
  keep_floating = function(w)
    local class = w.class or ""
    return class == "quarry"
      or class:find("LiveCaptions", 1, true) ~= nil
      or class:find("NautilusPreviewer", 1, true) ~= nil
      or class:find("satty", 1, true) ~= nil
      or w.title == "Picture-in-Picture"
  end,
}

-- Window state and workspace behavior.
local function xy(point) return point.x or point[1], point.y or point[2] end

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
    local match = window_rules.workspace_match(ws_selector(ws))
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
  local ws = hl.get_active_workspace()
  if not ws then return end

  local wins, all_floating = {}, true
  for _, w in ipairs(hl.get_windows()) do
    if w.workspace and w.workspace.id == ws.id and not w.pinned
        and not window_rules.keep_floating(w) then
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
  if not ok then print("[hyprland window behavior] " .. tostring(err)) end
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
  local mon = hl.get_monitors()[1]
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
  local w = hl.get_active_window()
  if w and w.floating then
    local ok, err = pcall(pseudo_maximize, w)
    if not ok then print("[hyprland window behavior] " .. tostring(err)) end
  else
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
  end
end)
