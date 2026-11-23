import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

// Shared row for popup lists (tray, Wi-Fi, Bluetooth).
// Icon may be a glyph (iconText) or an image path (iconSource). Extra children
// are appended as trailing widgets after the label.
Rectangle {
    id: root

    default property alias trailing: contentRow.data

    property string iconText: ""
    property var iconSource: ""
    property alias iconColor: iconGlyph.color
    property int iconSize: Theme.iconSize
    property alias label: labelText.text
    property alias labelColor: labelText.color
    property alias labelWeight: labelText.font.weight
    property alias labelFontSize: labelText.font.pixelSize
    property bool selected: false
    property bool interactionEnabled: true
    property real rowHeight: 40
    property real horizontalPadding: 10

    // Optional drag support, used by the tray overflow rows.
    property bool dragEnabled: false
    property real dragSurfaceX: 0
    property real dragSurfaceY: 0

    property alias mouseArea: rowMouse

    signal clicked(var mouse)
    signal hoverEntered()
    signal hoverExited()
    signal dragStarted(real x, real y)
    signal dragMoved(real x, real y)
    signal dragFinished(real x, real y)
    signal dragCanceled()

    Layout.fillWidth: true
    implicitHeight: root.rowHeight
    radius: Theme.itemRadius
    color: root.selected ? Qt.alpha(Theme.blue, 0.18)
        : rowMouse.containsMouse && root.interactionEnabled ? Theme.hover : "transparent"

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 10

        Text {
            id: iconGlyph
            visible: root.iconText !== ""
            font.family: Theme.nerdFont
            font.pixelSize: root.iconSize
            color: Qt.alpha(Theme.foreground, 0.55)
        }

        IconImage {
            id: iconImage
            visible: root.iconSource !== ""
            source: root.iconSource
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
            asynchronous: true
        }

        Text {
            id: labelText
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Medium
            color: Theme.foreground
        }
    }

    MouseArea {
        id: rowMouse
        property real pressX: 0
        property real pressY: 0
        property bool dragging: false
        property bool suppressClick: false

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactionEnabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root.hoverEntered()
        onExited: root.hoverExited()

        onPressed: mouse => {
            pressX = mouse.x;
            pressY = mouse.y;
            dragging = false;
            suppressClick = false;
        }

        onPositionChanged: mouse => {
            if (!root.dragEnabled || !(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) < 8) return;

            const scene = root.mapToItem(null, mouse.x, mouse.y);
            const screenX = root.dragSurfaceX + scene.x;
            const screenY = root.dragSurfaceY + scene.y;
            if (!dragging) {
                dragging = true;
                suppressClick = true;
                root.dragStarted(screenX, screenY);
            }
            root.dragMoved(screenX, screenY);
        }

        onReleased: mouse => {
            if (!dragging) return;
            const scene = root.mapToItem(null, mouse.x, mouse.y);
            dragging = false;
            root.dragFinished(root.dragSurfaceX + scene.x, root.dragSurfaceY + scene.y);
        }

        onCanceled: {
            const wasDragging = dragging;
            dragging = false;
            if (wasDragging) root.dragCanceled();
        }

        onClicked: mouse => {
            if (suppressClick) {
                suppressClick = false;
                return;
            }
            root.clicked(mouse);
        }
    }
}
