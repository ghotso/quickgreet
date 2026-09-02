import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// A row of selectable chips, used for both the user and session pickers.
//
// Chips rather than a dropdown: a greeter realistically has two or three
// options, and a flat row needs no popup, no focus stealing, and no z-order
// fights with a fullscreen layer-shell surface.
Flow {
    id: root

    property var model: []
    property int currentIndex: 0
    // Given a model entry, return its display label.
    property var labelFor: entry => String(entry)

    signal selected(int index)

    spacing: Tokens.px(Tokens.spacing.small)

    Repeater {
        model: root.model

        StyledRect {
            required property int index
            required property var modelData

            readonly property bool active: index === root.currentIndex

            implicitWidth: chipLabel.implicitWidth + Tokens.px(Tokens.padding.large) * 2
            implicitHeight: Tokens.px(32)
            radius: height / 2

            color: active ? (Colours.c.secondaryContainer ?? Colours.c.primaryContainer ?? Colours.c.surfaceContainerHighest) : "transparent"
            border.width: active ? 0 : Math.max(1, Tokens.px(1))
            border.color: Colours.c.outlineVariant ?? Colours.c.outline

            StyledText {
                id: chipLabel

                anchors.centerIn: parent
                text: root.labelFor(parent.modelData)
                font.pixelSize: Tokens.px(14)
                color: parent.active ? (Colours.c.onSecondaryContainer ?? Colours.c.onSurface) : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(parent.index)
            }
        }
    }
}
