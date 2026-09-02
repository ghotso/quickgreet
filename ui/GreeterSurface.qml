import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.components
import qs.config
import qs.services

// One screen's worth of greeter: wallpaper behind, two panes over it.
//
// Layout is clock-left / login-right on anything wide enough, collapsing to a
// centred stack on narrow screens. Both panes are placed as fractions of the
// screen rather than at fixed offsets, so the same design holds from 1080p up
// to an unscaled 4K panel.
FocusScope {
    id: root

    // The panes belong on one screen; others show only the wallpaper.
    property bool primary: true

    // Typography and spacing track panel height. Clamped at the bottom so a
    // small demo window stays usable, and at the top so a very tall panel
    // doesn't produce absurd type.
    readonly property real uiScale: Math.max(0.85, Math.min(2.4, height / 1080))

    readonly property bool compact: width < 1000

    focus: true
    Keys.onPressed: event => {
        Auth.handleKey(event);
        event.accepted = true;
    }

    onUiScaleChanged: if (primary)
        Tokens.scale = uiScale
    Component.onCompleted: if (primary)
        Tokens.scale = uiScale

    Background {
        anchors.fill: parent
    }

    // ---- wide: two panes ---------------------------------------------------
    Item {
        id: wide

        anchors.fill: parent
        anchors.leftMargin: parent.width * 0.09
        anchors.rightMargin: parent.width * 0.09
        visible: root.primary && !root.compact

        ClockPane {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - login.width - Tokens.px(48), parent.width * 0.55)
        }

        Shadowed {
            id: login
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ---- narrow: stacked ---------------------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.86, Tokens.px(Tokens.sizes.cardWidth))
        spacing: Tokens.px(Tokens.spacing.extraLarge)
        visible: root.primary && root.compact

        ClockPane {
            Layout.fillWidth: true
            compact: true
        }

        Shadowed {
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // Unmissable in demo mode: it must never be ambiguous whether the thing on
    // screen can actually log you in.
    StyledRect {
        visible: DevMode.enabled
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.px(Tokens.padding.large)
        implicitWidth: demoLabel.implicitWidth + Tokens.px(Tokens.padding.large) * 2
        implicitHeight: Tokens.px(30)
        radius: height / 2
        color: Colours.c.errorContainer ?? "#93000a"

        StyledText {
            id: demoLabel
            anchors.centerIn: parent
            text: `DEMO MODE — mock login (password: ${Config.dev.mockPassword})`
            color: Colours.c.onErrorContainer ?? "#ffdad6"
            font.pixelSize: Tokens.px(12)
            font.weight: Font.DemiBold
        }
    }

    // The login pane plus its drop shadow and entrance animation. Inline
    // component so both layout branches get identical treatment.
    component Shadowed: Item {
        implicitWidth: pane.implicitWidth
        implicitHeight: pane.implicitHeight

        LoginPane {
            id: pane
            anchors.fill: parent
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 24
            shadowColor: Qt.alpha(Colours.c.shadow ?? "#000000", 0.55)
            shadowVerticalOffset: 6
        }

        scale: 0.94
        opacity: 0
        Component.onCompleted: {
            scale = 1;
            opacity = 1;
        }

        Behavior on scale {
            Anim {
                type: Anim.Type.Spatial
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.durations.normal
            }
        }
    }
}
