
click empty status bar for a notes app appended up top

lockscreen

## Lock screen

The existing Quickshell session lock is enabled. Test it manually with
`qs ipc call lock lock`. The lock surface shows the current desktop wallpaper,
a read-only status bar, and a password prompt in the bottom-left corner.
Password and fingerprint authentication remain in `lock/LockContext.qml`.
Hypridle and `Super+L` still use the existing Hyprlock command until you
choose to switch them.

Do not restart Quickshell while the session is locked.

widget panel on the left

## Compositors

The shell detects Hyprland, MangoWM, and Niri from their session environment.
Under MangoWM, the workspace pills show the compositor's tags and the taskbar
uses `mmsg` client events. Install `mmsg` with MangoWM and start Quickshell from
the MangoWM session so `MANGO_INSTANCE_SIGNATURE` reaches it. The other bar
controls use Wayland, PipeWire, NetworkManager, BlueZ, or system services and do
not require Hyprland IPC.

