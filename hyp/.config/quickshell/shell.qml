//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.wallpaper
import qs.notifications
import qs.osd
import qs.lock
import qs.launcher
import qs.polkit

ShellRoot {
    Bar {}
    // Desktop {}
    NotificationPopups {}
    Osd {}
    Lock {}
    Launcher {}
    PolkitAuth {}
}
