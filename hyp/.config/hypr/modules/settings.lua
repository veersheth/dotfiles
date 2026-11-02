-- Display, input, animation, layout, and startup defaults.
return function(hl)
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
        enabled  = false,
        size     = 4,
        passes   = 2,
        vibrancy = 0,
        special  = false,
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

  return { gaps_in = GAPS_IN }
end
