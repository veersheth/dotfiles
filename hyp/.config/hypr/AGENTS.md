# Working in this Hyprland config

Read `README.md` first for the file map, shortcuts, helper scripts, and reload command.

## Structure

- `hyprland.lua` is the entry point. It loads `monitors.lua`, then the Lua modules in a deliberate order.
- Each file in `modules/` returns a registration function and receives the Hyprland Lua API as `hl`.
- `modules/settings.lua` returns shared tuning values. Keep settings that must stay synchronized, such as `GAPS_IN` and floating maximize margin, sourced from one value.
- `modules/bindings.lua` contains user shortcuts; keep `README.md`'s shortcut table in sync.
- Keep app matching and window rules in `modules/window-rules.lua`; window-state logic belongs in `modules/window-behavior.lua`.
- `monitors.lua` is machine-specific. Preserve monitor names, coordinates, scales, and workspace placement unless the task explicitly changes them.
- `hypridle.conf`, `hyprlock.conf`, and `scripts/` are runtime config and helpers. Update the README's project map or script table when adding or renaming files.

## Editing guidelines

- Preserve existing behavior unless the request calls for a behavior change. Explain any behavior change in the final summary.
- Keep scripts safe to invoke from a keybinding: validate arguments, quote paths, and report missing dependencies clearly.
- Treat `scripts/screenshot.sh lens` as an external upload: it sends the captured image to Catbox and Google Lens.
- Keep the misspelled `scripts/brightess.sh` compatibility alias until callers have had a migration path; new references should use `scripts/brightness.sh`.
- Preserve unrelated working-tree edits. Do not format or revert neighboring dotfiles as part of a Hyprland task.
- Reload an active session with `hyprctl reload` when applying config edits. A reload only works when the active Hyprland socket is available.
