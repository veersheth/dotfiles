//@ pragma UseQApplication
import Quickshell
import qs.bar
import qs.wallpaper
import qs.notifications
import qs.osd
import qs.dock
import qs.lock

ShellRoot {
    Bar {}
    Desktop { wallpaper: "/home/veer/dotfiles/wallpapers/wallpapers/valley-water.jpg" }
    NotificationPopups {}
    Osd {}
    Lock {}
    // Dock {}
}
