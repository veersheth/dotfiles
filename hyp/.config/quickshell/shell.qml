//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.wallpaper
import qs.notifications
import qs.osd
import qs.dock
import qs.lock
import qs.launcher

ShellRoot {
    Bar {}
    Desktop {}
    NotificationPopups {}
    Osd {}
    Lock {}
    Launcher {}
    // Dock {}
}
