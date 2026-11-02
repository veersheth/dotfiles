-- Individual and workspace float toggles plus the floating maximize action.
return function(hl, settings, expose, window_rules)
  local function xy(point) return point.x or point[1], point.y or point[2] end
  local GAPS_IN = settings.gaps_in

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
    if expose.active then return end

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
    if not ok then expose.log_error(err) end
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
      if not ok then expose.log_error(err) end
    else
      hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
    end
  end)

end
