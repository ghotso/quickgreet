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

    // Splits clockFormat into hour/minute/ampm/literal runs so each can be
    // coloured separately. Boundaries follow the same same-character-run rule
    // Qt.formatDateTime itself uses, so formatting each run separately and
    // concatenating them reads identically to formatting the whole string at
    // once.
    function tokenizeClock(fmt: string): var {
        const re = /AP|ap|H+|h+|m+|./g;
        const raw = [];
        let m;
        while ((m = re.exec(fmt)) !== null) {
            const t = m[0];
            let type;
            if (t === "AP" || t === "ap")
                type = "ampm";
            else if (t[0] === "H" || t[0] === "h")
                type = "hour";
            else if (t[0] === "m")
                type = "minute";
            else
                type = "literal";
            raw.push({
                type,
                text: t
            });
        }
        const merged = [];
        for (const r of raw) {
            const last = merged[merged.length - 1];
            if (last && last.type === "literal" && r.type === "literal")
                last.text += r.text;
            else
                merged.push({
                    type: r.type,
                    text: r.text
                });
        }
        return merged;
    }

    readonly property var clockTokens: root.tokenizeClock(Config.appearance.clockFormat)
    // Guards a pathological custom format (no hour/minute run at all) — fall
    // back to the single-colour rendering rather than show a blank clock.
    readonly property bool clockHasDigits: clockTokens.some(t => t.type === "hour" || t.type === "minute")
    readonly property bool clockIs12h: clockTokens.some(t => t.type === "ampm")
    readonly property string ampmToken: {
        const t = clockTokens.find(t => t.type === "ampm");
        return t ? t.text : "AP";
    }
    // AM/PM is pulled out into its own pill rather than rendered inline; drop
    // a lone trailing separator (" ", say) that AP/ap left behind.
    readonly property var clockInlineTokens: {
        let list = clockTokens.filter(t => t.type !== "ampm");
        if (list.length && list[list.length - 1].type === "literal" && !list[list.length - 1].text.trim().length)
            list = list.slice(0, -1);
        return list;
    }
    readonly property bool twoTone: Config.appearance.clockTwoTone && clockHasDigits

    StyledText {
        Layout.fillWidth: true
        visible: !root.twoTone
        horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignLeft
        text: Qt.formatDateTime(clock.date, Config.appearance.clockFormat)
        color: Colours.c.onSurface
        font.pixelSize: Tokens.px(root.compact ? 84 : 132)
        font.weight: Font.Light
        // The clock is the one element allowed to overhang its own line box;
        // a light-weight face at this size otherwise looks loose.
        lineHeight: 0.92
    }

    // Two-tone rendering: hour in the accent colour, minute in the secondary
    // colour, separators dimmed — the caelestia-inspired look.
    Row {
        Layout.alignment: root.compact ? Qt.AlignHCenter : Qt.AlignLeft
        visible: root.twoTone

        Repeater {
            model: root.clockInlineTokens

            StyledText {
                required property var modelData

                text: Qt.formatDateTime(clock.date, modelData.text)
                color: modelData.type === "hour" ? (Colours.c.primary ?? Colours.c.onSurface) : modelData.type === "minute" ? (Colours.c.secondary ?? Colours.c.primary ?? Colours.c.onSurface) : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface)
                font.pixelSize: Tokens.px(root.compact ? 84 : 132)
                font.weight: Font.Light
                lineHeight: 0.92
            }
        }
    }

    StyledRect {
        visible: root.twoTone && root.clockIs12h
        Layout.alignment: root.compact ? Qt.AlignHCenter : Qt.AlignLeft
        Layout.topMargin: Tokens.px(Tokens.spacing.extraSmall)
        implicitWidth: ampmLabel.implicitWidth + Tokens.px(Tokens.padding.normal) * 2
        implicitHeight: Tokens.px(24)
        radius: height / 2
        color: Colours.c.surfaceContainerHigh ?? Colours.c.surfaceContainer

        StyledText {
            id: ampmLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, root.ampmToken)
            color: Colours.c.onSurfaceVariant ?? Colours.c.onSurface
            font.pixelSize: Tokens.px(12)
            font.weight: Font.DemiBold
        }
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
