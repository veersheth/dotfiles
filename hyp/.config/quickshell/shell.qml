//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.wallpaper
import qs.notifications
import qs.osd
import qs.lock
import qs.launcher
import qs.polkit
import qs.flash
import qs.expose

ShellRoot {
    Desktop {}
    Bar {}
    Expose {}
    NotificationPopups {}
    Osd {}
    Lock {}
    Launcher {}
    PolkitAuth {}
    Flash {}
}
