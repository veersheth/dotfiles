import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.common

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: listView.contentWidth

    // Snapshot re-evaluates whenever toplevels are added/removed or change workspace.
    // Drives syncModel() so the ListModel stays in sorted order with per-item signals.
    readonly property var snapshot: Hyprland.toplevels.values
        .map(t => t.address + ":" + (t.workspace?.id ?? 999))
    onSnapshotChanged: syncModel()

    ListModel { id: taskModel }
    Component.onCompleted: syncModel()

    function syncModel() {
        const tops = Hyprland.toplevels.values
            .slice()
            .sort((a, b) => (a.workspace?.id ?? 999) - (b.workspace?.id ?? 999));

        for (let i = taskModel.count - 1; i >= 0; i--)
            if (!tops.some(t => t.address === taskModel.get(i).address))
                taskModel.remove(i);

        for (let si = 0; si < tops.length; si++) {
            const addr = tops[si].address;
            let mi = -1;
            for (let i = 0; i < taskModel.count; i++)
                if (taskModel.get(i).address === addr) { mi = i; break; }
            if (mi === -1)      taskModel.insert(si, { address: addr });
            else if (mi !== si) taskModel.move(mi, si, 1);
        }
    }

    function iconForApp(appId) {
        const id = (appId ?? "").toLowerCase();
        if (id.includes("firefox"))                            return "";
        if (id.includes("chrome") || id.includes("chromium")) return "";
        if (id.includes("kitty"))                              return "";
        if (id.includes("alacritty"))                          return "";
        if (id.includes("ghostty"))                            return "";
        if (id.includes("code") || id.includes("vscode") || id.includes("cursor")) return "󰨞";
        if (id.includes("nvim") || id.includes("neovim"))      return "";
        if (id.includes("nautilus") || id.includes("files"))   return "";
        if (id.includes("spotify"))                            return "";
        if (id.includes("discord"))                            return "󰙯";
        if (id.includes("telegram"))                           return "";
        if (id.includes("slack"))                              return "";
        if (id.includes("obsidian"))                           return "";
        if (id.includes("mpv"))                                return "";
        if (id.includes("vlc"))                                return "󰕼";
        if (id.includes("steam"))                              return "";
        if (id.includes("thunar"))                             return "󰝰";
        if (id.includes("blender"))                            return "󰂫";
        return "󰣆";
    }

    ListView {
        id: listView
        anchors.centerIn: parent
        orientation: ListView.Horizontal
        spacing: 6
        width: contentWidth
        height: Theme.barHeight
        model: taskModel
        clip: false

        populate: Transition {}

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "y"; from: 16; to: 0; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
                NumberAnimation { property: "y"; to: 16; duration: 220; easing.type: Easing.InCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: dlg
            required property string address

            readonly property var toplevel: {
                const arr = Hyprland.toplevels.values;
                return arr.find(t => t.address === dlg.address) ?? null;
            }
            readonly property string appId:    dlg.toplevel?.wayland?.appId ?? dlg.toplevel?.lastIpcObject?.class ?? ""
            readonly property bool   active:   dlg.toplevel?.activated ?? false
            readonly property bool   minimized: dlg.toplevel?.wayland?.minimized ?? false
            readonly property string iconSrc:  Quickshell.iconPath(dlg.appId, true)

            width: Theme.barHeight
            height: Theme.barHeight
            opacity: dlg.minimized ? 0.3 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Rectangle {
                anchors.fill: parent
                color: mo.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 28
                source: dlg.iconSrc
                visible: dlg.iconSrc !== ""
                opacity: dlg.active ? 1.0 : 0.75
                Behavior on opacity { NumberAnimation { duration: 150 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    saturation: dlg.active ? 0.0 : -1.0
                    Behavior on saturation { NumberAnimation { duration: 150 } }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: dlg.iconSrc === ""
                text: root.iconForApp(dlg.appId)
                font.family: Theme.nerdFont
                font.pixelSize: 20
                color: dlg.active ? Theme.blue : Qt.alpha(Theme.foreground, 0.6)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: mo
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (dlg.active) {
                        dlg.toplevel?.wayland?.setMinimized(true);
                    } else {
                        if (dlg.minimized) dlg.toplevel?.wayland?.setMinimized(false);
                        dlg.toplevel?.wayland?.activate();
                    }
                }
            }
        }
    }
}
