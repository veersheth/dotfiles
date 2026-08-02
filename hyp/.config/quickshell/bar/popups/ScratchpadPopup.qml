import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.common
import qs.components

BarPopup {
    id: root

    readonly property int shelfW: 190

    property bool loadedOk:    false
    property bool shelfLoaded: false
    property var  shelf:       []

    dismissOnFocusLoss: true
    alignLeft:          true

    contentWidth:   980
    contentHeight:  360
    contentPadding: 20

    onShownChanged: {
        if (shown) edit.forceActiveFocus();
        else if (loadedOk) file.setText(edit.text);
    }

    function addUrl(u) {
        if (!u || shelf.includes(u)) return;
        shelf = [...shelf, u];
        if (shelfLoaded) shelfFile.setText(JSON.stringify(shelf));
    }
    function removeUrl(u) {
        shelf = shelf.filter(x => x !== u);
        if (shelfLoaded) shelfFile.setText(JSON.stringify(shelf));
    }
    function isImage(u) { return /\.(png|jpe?g|webp|gif|svg|bmp|avif)$/i.test(u); }
    function fileIcon(u) {
        const ext = u.split(".").pop().toLowerCase();
        if (/^(png|jpe?g|webp|gif|svg|bmp|avif)$/.test(ext)) return { icon: "󰈟", color: Theme.blue };
        if (ext === "pdf")  return { icon: "󰈦", color: "#e06c75" };
        if (/^(mp4|mkv|mov|avi|webm)$/.test(ext)) return { icon: "󰈫", color: "#c678dd" };
        if (/^(mp3|flac|wav|ogg|m4a)$/.test(ext)) return { icon: "󰈣", color: Theme.green };
        if (/^(zip|tar|gz|xz|7z|rar)$/.test(ext)) return { icon: "󰿺", color: Theme.yellow };
        if (/^(txt|md|rst)$/.test(ext))            return { icon: "󰈙", color: Qt.alpha(Theme.foreground, 0.7) };
        return { icon: "󰈔", color: Qt.alpha(Theme.foreground, 0.55) };
    }

    // ── Persistence ────────────────────────────────────────────────────
    FileView {
        id: file
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/scratchpad.txt`
        printErrors: false; atomicWrites: true
        onLoaded:     { edit.text = text(); root.loadedOk = true; }
        onLoadFailed: root.loadedOk = true
    }
    FileView {
        id: shelfFile
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/scratchpad-shelf.json`
        printErrors: false; atomicWrites: true
        onLoaded:     { try { root.shelf = JSON.parse(text()); } catch (e) {} root.shelfLoaded = true; }
        onLoadFailed: root.shelfLoaded = true
    }
    Timer { id: saveDebounce; interval: 800; onTriggered: file.setText(edit.text) }

    // ── Text area ──────────────────────────────────────────────────────
    Flickable {
        id: flick
        anchors {
            top: parent.top; bottom: parent.bottom
            left: parent.left
            right: shelfPanel.visible ? shelfPanel.left : parent.right
        }
        contentHeight: edit.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: edit
            width: flick.width - 14
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            selectionColor: Qt.alpha(Theme.blue, 0.32)

            onTextChanged: if (root.loadedOk) saveDebounce.restart()
            Keys.onEscapePressed: root.close()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
                    const pos = cursorPosition; let i = pos;
                    while (i > 0 && /\s/.test(text.charAt(i - 1))) i--;
                    while (i > 0 && !/\s/.test(text.charAt(i - 1))) i--;
                    remove(i, pos); event.accepted = true;
                }
            }
            onCursorRectangleChanged: {
                const r = cursorRectangle;
                if (r.y < flick.contentY) flick.contentY = r.y;
                else if (r.y + r.height > flick.contentY + flick.height)
                    flick.contentY = r.y + r.height - flick.height;
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: vbar; policy: ScrollBar.AsNeeded; minimumSize: 0.06
            background: Item { implicitWidth: 14 }
            contentItem: Rectangle {
                implicitWidth: 3; radius: 1.5; color: Theme.foreground
                opacity: vbar.active ? (vbar.pressed ? 0.55 : 0.28) : 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Empty-state hint ───────────────────────────────────────────────
    Column {
        anchors { horizontalCenter: flick.horizontalCenter; verticalCenter: flick.verticalCenter }
        visible: edit.text === ""
        spacing: 10
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰠮"; font.family: Theme.nerdFont; font.pixelSize: 32
            color: Qt.alpha(Theme.foreground, 0.18)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Start typing or drop files…"
            font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.Medium
            color: Qt.alpha(Theme.foreground, 0.22)
        }
    }

    // ── Right shelf panel ──────────────────────────────────────────────
    Item {
        id: shelfPanel
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: root.shelfW
        visible: root.shelf.length > 0

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1; color: Qt.alpha(Theme.border, 0.5)
        }

        ListView {
            id: shelfList
            anchors { fill: parent; leftMargin: 1; topMargin: 2; bottomMargin: 2 }
            orientation: ListView.Vertical
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.shelf

            delegate: Item {
                id: chip
                required property string modelData
                required property int    index
                width: shelfList.width
                height: 48

                // Hover for the whole row
                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    // left-click opens only if not clicking the remove button
                    onClicked: mouse => {
                        if (mouse.x < parent.width - 36)
                            Quickshell.execDetached(["xdg-open", chip.modelData])
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: rowMa.containsMouse ? Theme.hover : "transparent"
                    radius: Theme.itemRadius
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Thumbnail
                Rectangle {
                    id: thumb
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 32; height: 32
                    radius: Theme.smallRadius
                    color: Qt.alpha(root.fileIcon(chip.modelData).color, 0.12)
                    border.width: Theme.borderWidth
                    border.color: Qt.alpha(root.fileIcon(chip.modelData).color, 0.35)

                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({ "text/uri-list": chip.modelData })

                    ClippingRectangle {
                        anchors.fill: parent; anchors.margins: Theme.borderWidth
                        radius: Theme.smallRadius; color: "transparent"
                        visible: root.isImage(chip.modelData)
                        Image {
                            anchors.fill: parent; source: chip.modelData
                            fillMode: Image.PreserveAspectCrop; asynchronous: true
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !root.isImage(chip.modelData)
                        text: root.fileIcon(chip.modelData).icon
                        font.family: Theme.nerdFont; font.pixelSize: 16
                        color: root.fileIcon(chip.modelData).color
                    }

                    DragHandler {
                        onActiveChanged: {
                            if (active) {
                                thumb.grabToImage(res => {
                                    thumb.Drag.imageSource = res.url;
                                    thumb.Drag.active = true;
                                });
                            } else { thumb.Drag.active = false; }
                        }
                    }
                }

                // Filename
                Text {
                    anchors {
                        left: thumb.right; leftMargin: 10
                        right: removeBtn.left; rightMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    text: decodeURIComponent(chip.modelData.split("/").pop())
                    font.family: Theme.font; font.pixelSize: Theme.fontSize
                    color: Theme.foreground
                    elide: Text.ElideMiddle
                    maximumLineCount: 2
                    wrapMode: Text.WrapAnywhere
                }

                // ✕ remove button
                Rectangle {
                    id: removeBtn
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 20; height: 20; radius: 10
                    visible: rowMa.containsMouse
                    color: removeMa.containsMouse ? Theme.red : Qt.alpha(Theme.foreground, 0.12)
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Text {
                        anchors.centerIn: parent; text: "✕"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: removeMa.containsMouse ? "white" : Qt.alpha(Theme.foreground, 0.7)
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }

                    MouseArea {
                        id: removeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.removeUrl(chip.modelData)
                    }
                }
            }
        }
    }

    // ── Drop target (receives files dragged in) ────────────────────────
    DropArea {
        anchors.fill: parent
        z: 10
        onDropped: drop => {
            if (drop.hasUrls) {
                for (const u of drop.urls) root.addUrl(u.toString());
                drop.accept(Qt.CopyAction);
            }
        }
    }
}
