# quickshell config

A translucent, docked status bar with inverted "melt" corners for Hyprland built with [Quickshell](https://quickshell.outfoxxed.me/).

```
╭──────────────────────────────────────────────────────────────────────────────╮
│ (● ─ ●)  ( Firefox)      (󰐊 Artist - Song) (tray) (󰂱 󰤨) (󰥔 Sun Jul 04 …) (󰁹 87%) │
╰──────────────────────────────────────────────────────────────────────────────╯
```

## Layout

- **Left:** Hyprland workspaces (plain dots, click to switch) · focused window class (pill)
- **Right:** MPRIS media · system tray · bluetooth · wifi · clock (pill) · battery (flashes red below 10%)

### Interactions

| Module    | Click                                    | Other |
| --------- | ---------------------------------------- | ----- |
| Media     | popup: art, seek bar, prev/play/next, shuffle, loop | middle-click: next track |
| Clock     | popup: calendar with vertically scrolling months (wheel/arrows, click title for today) | |
| Battery   | popup: power profile picker (power-profiles-daemon) | |
| Wifi      | `hypr-settings --wifi`                   | |
| Bluetooth | `hypr-settings --bluetooth`              | |
| Tray      | activate item                            | right-click: styled item menu (inline submenus) |

## Structure

```
shell.qml            entry point
common/              shared singletons
  Theme.qml          colors, fonts, metrics — restyle everything here
components/          reusable building blocks
  Pill.qml           rounded "island" container (clickable: true for a pointer + clicked())
  BarPopup.qml       animated popup card anchored below a bar module
  RoundCorner.qml    concave "melt" corner canvas
bar/                 the bar and its modules
  Bar.qml            per-screen panel window + module rows
  *.qml              one file per module
  popups/            popups opened from bar modules
```

Directories are imported with quickshell's config-root imports (`import qs.common`,
`import qs.components`, `import qs.bar.popups`); files in the same directory see each
other automatically, so there are no `qmldir` files to maintain. New top-level pieces
(launcher, notifications, …) should get their own directory next to `bar/` and be
instantiated from `shell.qml`.

## Requirements

- `quickshell` 0.3+ (uses `Quickshell.Bluetooth`, `Quickshell.Services.UPower`, `Quickshell.Services.Mpris`)
- Hyprland (workspaces, dispatch, popup focus grabs)
- `NetworkManager` (`nmcli`) for the wifi indicator
- `power-profiles-daemon` for the battery popup
- `hypr-settings` for the wifi/bluetooth click actions
- Fonts: **Inter** and **JetBrainsMono Nerd Font**

## Install

```sh
cp -r quickshell-bar ~/.config/quickshell
quickshell        # or: qs
```

Or keep multiple configs:

```sh
cp -r quickshell-bar ~/.config/quickshell/bar
qs -c bar
```

Autostart in `hyprland.conf`:

```
exec-once = quickshell
```

## Customization

Everything lives in **`common/Theme.qml`** — colors, fonts, bar height, radius, animation speed.
Heads up: QML color hex is `#AARRGGBB` (alpha *first*), so web-style `#RRGGBBAA` values
are already converted for you in that file (e.g. `#00000088` → `#88000000`).

- Bar height: `barHeight` (34) · melt corner radius: `radius` (20)
- Popup corner radius: `popupRadius` · popup gap/animation: `components/BarPopup.qml`

## Troubleshooting

- **Boxes instead of icons** → the Nerd Font isn't installed or is named differently; check with `fc-list | grep -i jetbrains`.
- **No wifi icon updates** → make sure `nmcli` works in a terminal.
- **No bluetooth module** → your quickshell build may predate `Quickshell.Bluetooth`; update quickshell.
- **Battery hidden** → it auto-hides on machines without a laptop battery.
- **Battery popup empty/stuck on Balanced** → `power-profiles-daemon` isn't running.
