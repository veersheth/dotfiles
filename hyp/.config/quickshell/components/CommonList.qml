import QtQuick
import QtQuick.Layouts
import qs.common

// Fixed-width ColumnLayout shell. Children use Layout.fillWidth: true to fill.
// Popups wrap around this: contentWidth = Theme.listWidth + 2 * contentPadding.
ColumnLayout {
    spacing: 2
    implicitWidth: Theme.listWidth
}
