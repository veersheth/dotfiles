import Quickshell
import QtQuick
import qs.common
import qs.wallpaper

Item {
    id: root
    required property var ctx
    opacity: 0

    // Use the exact source and crop mode of the desktop wallpaper.
    Rectangle {
        anchors.fill: parent
        color: WallpaperService.isColor ? WallpaperService.colorValue : "black"
    }
    Image {
        anchors.fill: parent
        visible: !WallpaperService.isColor
        source: !WallpaperService.isColor && WallpaperService.imagePath.length > 0
            ? "file://" + WallpaperService.imagePath : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }

    // Keep the prompt legible over bright wallpapers without hiding the image.
    Rectangle {
        id: promptScrim
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.min(parent.height, 245)
        opacity: 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#00000000" }
            GradientStop { position: 1; color: "#b8000000" }
        }
    }

    LockBar {}

    Column {
        id: prompt
        anchors.left: parent.left
        anchors.leftMargin: Math.min(48, Math.max(24, root.width * 0.04))
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.min(48, Math.max(24, root.height * 0.05))
        spacing: 13
        width: Math.max(1, root.width - anchors.leftMargin - 24)
        opacity: 0
        transform: Translate { id: promptOffset; y: 14 }

        Text {
            text: Quickshell.env("USER") || "User"
            font.family: Theme.font
            font.pixelSize: 21
            font.weight: Font.DemiBold
            color: "white"
        }

        Rectangle {
            width: Math.min(340, parent.width)
            height: 44
            radius: 11
            color: "#aa101010"
            border.width: 1
            border.color: root.ctx.status === "Incorrect password" ? Theme.red
                : input.activeFocus ? Theme.foreground : Theme.border

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: "Password"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Qt.alpha(Theme.foreground, 0.55)
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.foreground
                clip: true
                enabled: !root.ctx.authenticating && !root.ctx.succeeded
                onTextChanged: root.ctx.currentText = text
                onAccepted: root.ctx.submit()
                Component.onCompleted: forceActiveFocus()
                Accessible.name: "Password"

                Connections {
                    target: root.ctx
                    function onCurrentTextChanged() {
                        if (root.ctx.currentText === "") input.text = ""
                    }
                    function onFailed() { input.forceActiveFocus() }
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.ctx.authenticating ? "Checking password…"
                : root.ctx.status !== "" ? root.ctx.status
                : "Touch the fingerprint reader or enter your password"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: root.ctx.status === "Incorrect password" ? "#ff8b8b"
                : Qt.alpha(Theme.foreground, 0.72)
        }
    }

    ParallelAnimation {
        id: enterAnimation
        running: true
        NumberAnimation { target: prompt; property: "opacity"; from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic }
        NumberAnimation { target: promptOffset; property: "y"; from: 14; to: 0; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: promptScrim; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 440; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: exitAnimation
        NumberAnimation { target: prompt; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
        NumberAnimation { target: promptOffset; property: "y"; to: 10; duration: 260; easing.type: Easing.InCubic }
        NumberAnimation { target: promptScrim; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 360; easing.type: Easing.InCubic }
    }

    Connections {
        target: root.ctx
        function onSucceededChanged() {
            if (root.ctx.succeeded) exitAnimation.start()
        }
    }
}
