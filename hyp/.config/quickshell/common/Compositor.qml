pragma Singleton
import Quickshell
import QtQuick

QtObject {
    readonly property bool mango: !!Quickshell.env("MANGO_INSTANCE_SIGNATURE")
    readonly property bool hyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property bool niri: !mango && !hyprland && !!Quickshell.env("NIRI_SOCKET")
}
