import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.components

BarPopup {
    id: root
    contentWidth: 332
    contentHeight: column.implicitHeight + 2 * contentPadding
    handleEscape: false

    property string pendingAction: ""
    property string errorText: ""
    readonly property var actionNames: ({ lock: "Lock", suspend: "Sleep", reboot: "Restart", poweroff: "Shut down", logout: "Log out" })
    readonly property var explanations: ({
        reboot: "Closes your apps and restarts the computer.",
        poweroff: "Closes your apps and turns off the computer.",
        logout: "Closes your apps and ends this session."
    })

    function commandFor(action) {
        switch (action) {
        case "lock": return ["loginctl", "lock-session"];
        case "suspend": return ["systemctl", "suspend"];
        case "reboot": return ["systemctl", "reboot"];
        case "poweroff": return ["systemctl", "poweroff"];
        case "logout": return ["uwsm", "stop"];
        default: return [];
        }
    }
    function execute(action) {
        if (actionProcess.running) return;
        const command = commandFor(action);
        if (!command.length) return;
        actionProcess.command = command;
        close();
        actionProcess.running = true;
    }
    function choose(action) {
        if (action === "lock" || action === "suspend") execute(action);
        else {
            pendingAction = action;
            cancelButton.forceActiveFocus();
        }
    }
    onShownChanged: {
        if (shown) {
            pendingAction = "";
            errorText = "";
            Qt.callLater(() => { if (root.shown) lockTile.forceActiveFocus(); });
        }
    }
    Process {
        id: actionProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.shown = true;
                root.errorText = "Couldn't complete the action. Please try again.";
            }
        }
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: {
            if (root.pendingAction !== "") {
                root.pendingAction = "";
                lockTile.forceActiveFocus();
            } else root.close();
        }
    }

    component ActionTile: AbstractButton {
        id: tile
        property string glyph: ""
        property color tint: Theme.foreground
        implicitWidth: 144
        implicitHeight: 88
        Layout.fillWidth: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        background: Rectangle {
            radius: Theme.itemRadius
            color: tile.down ? Qt.alpha(tile.tint, 0.18)
                : tile.hovered ? Qt.alpha(tile.tint, 0.11) : Qt.alpha(tile.tint, 0.045)
            border.width: 1
            border.color: tile.visualFocus ? Theme.blue : Qt.alpha(tile.tint, 0.10)
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        contentItem: Column {
            spacing: 10
            topPadding: 17
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.glyph
                font.family: Theme.nerdFont
                font.pixelSize: 24
                color: tile.tint
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }
        }
    }
    component MenuButton: AbstractButton {
        id: button
        property bool destructive: false
        implicitHeight: 38
        Layout.fillWidth: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        background: Rectangle {
            radius: Theme.smallRadius
            color: button.destructive ? Qt.alpha(Theme.red, button.down ? 0.3 : button.hovered ? 0.24 : 0.15)
                : button.down ? Theme.hoverStrong : button.hovered ? Theme.hover : "transparent"
            border.width: 1
            border.color: button.visualFocus ? Theme.blue
                : button.destructive ? Qt.alpha(Theme.red, 0.35) : Qt.alpha(Theme.foreground, 0.12)
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        contentItem: Text {
            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: button.destructive ? Theme.red : Theme.foreground
        }
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                implicitWidth: 40; implicitHeight: 40
                radius: 12
                color: Qt.alpha(Theme.blue, 0.12)
                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Theme.nerdFont
                    font.pixelSize: 22
                    color: Theme.blue
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Power"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                    font.weight: Font.DemiBold
                    color: Theme.foreground
                }
                Text {
                    text: Quickshell.env("USER") || "Session controls"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    color: Qt.alpha(Theme.foreground, 0.55)
                }
            }
        }

        GridLayout {
            visible: root.pendingAction === ""
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            ActionTile { id: lockTile; text: "Lock"; glyph: "󰌾"; onClicked: root.choose("lock") }
            ActionTile { text: "Sleep"; glyph: "󰤄"; onClicked: root.choose("suspend") }
            ActionTile { text: "Restart"; glyph: "󰜉"; onClicked: root.choose("reboot") }
            ActionTile { text: "Shut down"; glyph: "󰐥"; tint: Theme.red; onClicked: root.choose("poweroff") }
        }

        MenuButton {
            visible: root.pendingAction === ""
            text: "Log out"
            onClicked: root.choose("logout")
        }

        ColumnLayout {
            visible: root.pendingAction !== ""
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: (root.actionNames[root.pendingAction] || "") + "?"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                font.weight: Font.DemiBold
                color: Theme.foreground
            }
            Text {
                Layout.fillWidth: true
                text: root.explanations[root.pendingAction] || ""
                wrapMode: Text.WordWrap
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Qt.alpha(Theme.foreground, 0.65)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8
                MenuButton {
                    id: cancelButton
                    text: "Cancel"
                    onClicked: { root.pendingAction = ""; lockTile.forceActiveFocus(); }
                }
                MenuButton {
                    text: root.actionNames[root.pendingAction] || "Confirm"
                    destructive: true
                    onClicked: root.execute(root.pendingAction)
                }
            }
        }
        Text {
            visible: root.errorText !== ""
            Layout.fillWidth: true
            text: root.errorText
            wrapMode: Text.WordWrap
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: Theme.red
        }
    }
}
