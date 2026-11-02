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

ShellRoot {
    Desktop {}
    Bar {}
    NotificationPopups {}
    Osd {}
    Lock {}
    Launcher {}
    PolkitAuth {}
    Flash {}
}
