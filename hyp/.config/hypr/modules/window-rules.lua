-- Static window and layer rules, including app-specific behavior.
return function(hl)
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
  return {
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
end
