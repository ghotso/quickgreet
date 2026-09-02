import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

// The time side of the two-pane layout.
//
// Sits directly on the wallpaper with no card behind it — the contrast between
// a big unadorned clock and the contained login card is what makes the split
// read as deliberate rather than as two boxes.
ColumnLayout {
    id: root

    property bool compact: false

    spacing: Tokens.px(Tokens.spacing.small)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignLeft
        text: Qt.formatDateTime(clock.date, Config.appearance.clockFormat)
        color: Colours.c.onSurface
        font.pixelSize: Tokens.px(root.compact ? 84 : 132)
        font.weight: Font.Light
        // The clock is the one element allowed to overhang its own line box;
        // a light-weight face at this size otherwise looks loose.
        lineHeight: 0.92
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignLeft
        text: Qt.formatDateTime(clock.date, Config.appearance.dateFormat).toUpperCase()
        color: Colours.c.onSurfaceVariant ?? Colours.c.onSurface
        font.pixelSize: Tokens.px(18)
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.px(2.2)
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.px(Tokens.spacing.small)
        visible: text.length
        horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignLeft
        text: Config.appearance.greeting ?? ""
        color: Colours.c.onSurfaceVariant ?? Colours.c.onSurface
        font.pixelSize: Tokens.px(16)
        wrapMode: Text.WordWrap
    }
}
