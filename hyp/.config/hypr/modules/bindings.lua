-- Daily-use shortcuts. See README.md for the user-facing shortcut map.
return function(hl)
  --------------------------
  ---- WINDOW STATE      ----
  --------------------------

  hl.bind("SUPER + P",         hl.dsp.window.pseudo())                            -- toggle pseudo
  hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())                                               -- fullscreen

  --------------------------
  ---- FOCUS / CYCLE     ----
  --------------------------

  -- SUPER + J / K are defined further down (switcher_step), after the expose code.
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
  hl.bind("SUPER + XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight"))  -- nightlight
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

end
