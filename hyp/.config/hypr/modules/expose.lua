-- Workspace overview and navigation while the overview is active.
return function(hl)
  ------------------------------------------------
  ---- EXPOSE                                  ----
  ------------------------------------------------

  local expose = { active = false, switcher = false, saved = {} }

  local function dbg(msg)
    print("[hyprland expose] " .. tostring(msg))
  end

  local function xy(t) return t.x or t[1], t.y or t[2] end

  local MAX_SCALE = 0.95

  local function wkey(w)
    return tostring(w.address or w)
  end

  local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
  end

  local function overlap(a, b, gap)
    return (a.width + b.width) / 2 + gap - math.abs(a.x - b.x),
           (a.height + b.height) / 2 + gap - math.abs(a.y - b.y)
  end

  -- Map each original center by its angle and distance from the monitor center,
  -- then resolve overlaps. Equal centers get stable angles around a small ring.
  -- This only moves real windows; it keeps no screencopy previews running.
  local function spread_positions(wins, mon)
    local sc  = mon.scale or 1
    local mw, mh = mon.width / sc, mon.height / sc
    local mx, my = mon.x or 0, mon.y or 0
    local margin = math.min(48, math.min(mw, mh) * 0.04)
    local area_w, area_h = mw - 2 * margin, mh - 2 * margin
    local left, top = mx + margin, my + margin
    local gap = math.min(20, math.min(area_w, area_h) * 0.025)

    table.sort(wins, function(a, b)
      if a.cy ~= b.cy then return a.cy < b.cy end
      if a.cx ~= b.cx then return a.cx < b.cx end
      return wkey(a.win) < wkey(b.win)
    end)

    local weighted_area = 0
    for _, it in ipairs(wins) do
      it.boost = 1.5 - 0.5 * math.min(1, it.sh / mh)
      weighted_area = weighted_area + it.sw * it.sh * it.boost * it.boost
    end
    local scale = math.min(MAX_SCALE,
      math.sqrt(area_w * area_h / (weighted_area * 1.45)))
    for _, it in ipairs(wins) do
      scale = math.min(scale, area_w / (it.sw * it.boost),
        area_h / (it.sh * it.boost))
    end

    local jitter = math.min(10, math.min(area_w, area_h) * 0.01)
    for _ = 1, 12 do
      for i, it in ipairs(wins) do
        local window_scale = math.min(MAX_SCALE, scale * it.boost)
        it.width, it.height = it.sw * window_scale, it.sh * window_scale
        local angle = 2 * math.pi * (i - 1) / #wins
        local px = (it.cx - mx - mw / 2) / (mw / 2)
        local py = (it.cy - my - mh / 2) / (mh / 2)
        local original_radius = math.sqrt(px * px + py * py)
        local ux, uy, radius
        if original_radius < 0.005 then
          ux, uy = math.cos(angle), math.sin(angle)
          radius = 0.22
        else
          ux, uy = px / original_radius, py / original_radius
          radius = 0.20 + 0.35 * math.min(1, original_radius)
        end
        it.x = left + area_w / 2 + ux * radius * area_w / 2
          + math.cos(angle) * jitter
        it.y = top + area_h / 2 + uy * radius * area_h / 2
          + math.sin(angle) * jitter
        it.x = clamp(it.x, left + it.width / 2, left + area_w - it.width / 2)
        it.y = clamp(it.y, top + it.height / 2, top + area_h - it.height / 2)
      end

      for _ = 1, 90 do
        local collided = false
        for i = 1, #wins - 1 do
          local a = wins[i]
          for j = i + 1, #wins do
            local b = wins[j]
            local ox, oy = overlap(a, b, gap)
            if ox > 0.5 and oy > 0.5 then
              collided = true
              local dx, dy = a.x - b.x, a.y - b.y
              if math.abs(dx) + math.abs(dy) < 0.001 then
                local angle = (i * 2.4 + j * 1.3)
                dx, dy = math.cos(angle), math.sin(angle)
              end
              local length = math.sqrt(dx * dx + dy * dy)
              local ux, uy = dx / length, dy / length
              local distance = math.min(
                ox / math.max(math.abs(ux), 0.001),
                oy / math.max(math.abs(uy), 0.001))
              local step = (distance + 0.5) / 2
              a.x, b.x = a.x + ux * step, b.x - ux * step
              a.y, b.y = a.y + uy * step, b.y - uy * step
            end
          end
        end
        for _, it in ipairs(wins) do
          it.x = clamp(it.x, left + it.width / 2, left + area_w - it.width / 2)
          it.y = clamp(it.y, top + it.height / 2, top + area_h - it.height / 2)
        end
        if not collided then break end
      end

      local clear = true
      for i = 1, #wins - 1 do
        for j = i + 1, #wins do
          local ox, oy = overlap(wins[i], wins[j], gap)
          if ox > 1 and oy > 1 then clear = false; break end
        end
        if not clear then break end
      end
      if clear then break end
      scale = scale * 0.88
    end

    -- Center the whole constellation without changing its gaps. For one
    -- window this naturally places that window in the monitor center.
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    local min_dx, min_dy = -math.huge, -math.huge
    local max_dx, max_dy = math.huge, math.huge
    for _, it in ipairs(wins) do
      min_x = math.min(min_x, it.x - it.width / 2)
      max_x = math.max(max_x, it.x + it.width / 2)
      min_y = math.min(min_y, it.y - it.height / 2)
      max_y = math.max(max_y, it.y + it.height / 2)
      min_dx = math.max(min_dx, left + it.width / 2 - it.x)
      max_dx = math.min(max_dx, left + area_w - it.width / 2 - it.x)
      min_dy = math.max(min_dy, top + it.height / 2 - it.y)
      max_dy = math.min(max_dy, top + area_h - it.height / 2 - it.y)
    end
    local dx = clamp(left + area_w / 2 - (min_x + max_x) / 2, min_dx, max_dx)
    local dy = clamp(top + area_h / 2 - (min_y + max_y) / 2, min_dy, max_dy)
    for _, it in ipairs(wins) do
      it.x, it.y = it.x + dx, it.y + dy
    end
  end

  -- Resize and move the real windows; keep their original geometry for exit.
  local function place_windows(wins)
    spread_positions(wins, hl.get_monitors()[1])

    expose.saved = {}
    for _, it in ipairs(wins) do
      expose.saved[#expose.saved + 1] = {
        win = it.win, x = it.ax, y = it.ay,
        w = it.sw, h = it.sh, tiled = it.tiled,
      }
      hl.dispatch(hl.dsp.window.resize({ x = it.width, y = it.height, window = it.win }))
      hl.dispatch(hl.dsp.window.move({
        x = it.x - it.width / 2, y = it.y - it.height / 2, window = it.win,
      }))
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
      if w.workspace and w.workspace.id == ws.id and w.at and w.size then
        local ax, ay = xy(w.at)
        local sw, sh = xy(w.size)
        if ax and ay and sw and sh and sw > 1 and sh > 1 then
          table.insert(wins, {
            win = w, ax = ax, ay = ay, sw = sw, sh = sh,
            cx = ax + sw / 2, cy = ay + sh / 2,
            tiled = not w.floating,
          })
        end
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

  hl.define_submap("expose", function()
    hl.bind("escape", exit_expose)
    hl.bind("return", exit_expose)
    hl.bind("Tab", hl.dsp.window.cycle_next())
    hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh active-output"))
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

  expose.open = function()
    if expose.active then return end
    local ok, err = pcall(enter_expose)
    if not ok then dbg("error: " .. err) end
  end
  expose.close = function()
    if not expose.active then return end
    local ok, err = pcall(exit_expose)
    if not ok then dbg("error: " .. err) end
  end
  expose.toggle = function()
    if expose.active then expose.close() else expose.open() end
  end
  expose.log_error = function(err) dbg("error: " .. err) end
  return expose
end
