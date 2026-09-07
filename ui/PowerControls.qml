import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Suspend / reboot / power off, reachable without logging in first.
//
// Reboot and power off need a confirming second click — logind's
// allow_active policy (the greeter's session is always the active one) lets
// them succeed with no prompt at all, and its `-multiple-sessions` variants
// mean a stray click can take another logged-in session down too. Suspend is
// trivially reversible and runs on the first click.
RowLayout {
    id: root

    visible: Power.enabled.length > 0
    spacing: Tokens.px(Tokens.spacing.large)

    // Name of the verb currently armed (awaiting its confirming click), or "".
    property string armed: ""

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armed = ""
    }

    function activate(verb: var): void {
        if (verb.confirm && root.armed !== verb.name) {
            root.armed = verb.name;
            disarmTimer.restart();
            return;
        }
        root.armed = "";
        disarmTimer.stop();
        Power.run(verb.name);
    }

    Connections {
        target: Power
        function onActionFailed(message: string): void {
            root.armed = "";
            Auth.fail(message);
        }
    }

    Repeater {
        model: Power.enabled

        Button {
            armed: root.armed === modelData.name
            onActivated: root.activate(modelData)
        }
    }

    // Circular glyph button + caption, one per verb. Inline component so the
    // Repeater delegate and the drawing logic live in one place.
    component Button: ColumnLayout {
        id: btn

        required property var modelData
        property bool armed: false
        signal activated

        readonly property bool danger: btn.armed && btn.modelData.confirm

        spacing: Tokens.px(Tokens.spacing.extraSmall)

        StyledRect {
            Layout.preferredWidth: Tokens.px(44)
            Layout.preferredHeight: Tokens.px(44)
            Layout.alignment: Qt.AlignHCenter
            radius: width / 2
            color: btn.danger ? (Colours.c.errorContainer ?? "#93000a") : (hover.containsMouse ? (Colours.c.surfaceContainerHigh ?? Colours.c.surfaceContainer) : "transparent")
            border.width: btn.danger ? 0 : Math.max(1, Tokens.px(1))
            border.color: Colours.c.outlineVariant ?? Colours.c.outline

            Canvas {
                id: glyph
                anchors.centerIn: parent
                width: Tokens.px(20)
                height: Tokens.px(20)

                readonly property color stroke: btn.danger ? (Colours.c.onErrorContainer ?? "#ffdad6") : (hover.containsMouse ? (Colours.c.onSurface) : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface))
                onStrokeChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                // Hand-drawn, on a 20x20 design grid — same approach as the
                // eye/chevron glyphs in PasswordField.qml, so no icon-font
                // dependency reaches a greeter's bare fontconfig.
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const s = width / 20;
                    ctx.strokeStyle = stroke;
                    ctx.fillStyle = stroke;
                    ctx.lineWidth = 1.7 * s;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    if (btn.modelData.name === "suspend") {
                        // Crescent moon: two overlapping circular arcs closed
                        // into one filled path.
                        ctx.beginPath();
                        ctx.arc(10 * s, 10 * s, 7 * s, Math.PI * 0.55, Math.PI * 1.85, false);
                        ctx.arc(12.6 * s, 10 * s, 5.6 * s, Math.PI * 1.85, Math.PI * 0.55, true);
                        ctx.closePath();
                        ctx.fill();
                    } else if (btn.modelData.name === "reboot") {
                        // Refresh-style arrow: most of a circle, plus a
                        // triangular arrowhead at the open end.
                        const cx = 10 * s, cy = 10 * s, r = 6.5 * s;
                        const end = -Math.PI * 0.15;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, Math.PI * 0.2, end, false);
                        ctx.stroke();

                        const ex = cx + r * Math.cos(end);
                        const ey = cy + r * Math.sin(end);
                        ctx.beginPath();
                        ctx.moveTo(ex - 3.4 * s, ey - 1.2 * s);
                        ctx.lineTo(ex + 0.6 * s, ey - 3.4 * s);
                        ctx.lineTo(ex + 1.4 * s, ey + 1 * s);
                        ctx.closePath();
                        ctx.fill();
                    } else {
                        // Power symbol: a circle with a gap at the top, and a
                        // stem running into it.
                        const cx = 10 * s, cy = 11 * s, r = 6.4 * s;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI * 0.68, Math.PI * 1.18, false);
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.moveTo(cx, cy - r - 1.6 * s);
                        ctx.lineTo(cx, cy - 1 * s);
                        ctx.stroke();
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btn.activated()
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: btn.danger ? "Confirm?" : btn.modelData.label
            font.pixelSize: Tokens.px(11)
            color: btn.danger ? (Colours.c.error ?? "#ffb4ab") : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface)
        }
    }
}
