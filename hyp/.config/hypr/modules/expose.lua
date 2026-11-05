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
    fingers = 3,
    direction = "up",
    action = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call expose open")) end,
  })
  hl.gesture({
    fingers = 3,
    direction = "down",
    action = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call expose close")) end,
  })

  expose.log_error = function(err) dbg("error: " .. err) end
  return expose
end
