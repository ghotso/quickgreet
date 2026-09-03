import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Pill-shaped password field.
//
// There is no TextInput here on purpose: keystrokes are buffered in Auth so the
// password lives in exactly one place, and so submit/clear semantics are the
// same whether input came from the keyboard or (later) anywhere else.
StyledRect {
    id: root

    readonly property bool errored: Auth.status === Auth.Status.Failed

    implicitWidth: Tokens.px(Tokens.sizes.passwordWidth)
    implicitHeight: Tokens.px(52)
    radius: height / 2
    color: Colours.c.surfaceContainerHigh ?? Colours.c.surfaceContainer

    border.width: errored ? Tokens.px(2) : 0
    border.color: Colours.c.error ?? "#ff5555"

    Behavior on border.width {
        NumberAnimation {
            duration: Tokens.durations.fastEffects
        }
    }

    // Shake on failure — the same "something went wrong" pulse the lock screen
    // uses, which reads faster than text alone.
    SequentialAnimation {
        id: shake
        running: false
        NumberAnimation {
            target: root
            property: "anchors.horizontalCenterOffset"
            to: 9
            duration: 55
        }
        NumberAnimation {
            target: root
            property: "anchors.horizontalCenterOffset"
            to: -9
            duration: 55
        }
        NumberAnimation {
            target: root
            property: "anchors.horizontalCenterOffset"
            to: 5
            duration: 55
        }
        NumberAnimation {
            target: root
            property: "anchors.horizontalCenterOffset"
            to: 0
            duration: 55
        }
    }

    Connections {
        target: Auth
        function onFlashMsg(): void {
            shake.restart();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.px(Tokens.padding.large)
        anchors.rightMargin: Tokens.px(Tokens.padding.small)
        spacing: Tokens.px(Tokens.spacing.small)

        // Dots for typed characters, or the prompt/placeholder when empty.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: !Auth.buffer.length
                text: Auth.busy ? "Authenticating…" : (Auth.prompt || "Enter your password")
                color: Colours.c.onSurfaceVariant ?? Colours.c.onSurface
                font.pixelSize: Tokens.px(15)
                opacity: 0.9
            }

            // Echoed responses (an OTP prompt, say) are shown in clear; a
            // password is not.
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: Auth.buffer.length && Auth.echo
                text: Auth.buffer
                font.pixelSize: Tokens.px(16)
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: Auth.buffer.length && !Auth.echo
                spacing: Tokens.px(7)

                Repeater {
                    model: Math.min(Auth.buffer.length, 24)

                    StyledRect {
                        implicitWidth: Tokens.px(8)
                        implicitHeight: Tokens.px(8)
                        radius: Tokens.px(4)
                        color: Colours.c.onSurface

                        // Each new dot pops in rather than appearing, so typing
                        // feels responsive even with no character echo.
                        scale: 0
                        Component.onCompleted: scale = 1

                        Behavior on scale {
                            Anim {
                                type: Anim.Type.Spatial
                                duration: Tokens.durations.fastEffects
                            }
                        }
                    }
                }
            }
        }

        // Submit affordance. Drawn, not a font glyph — see Avatar.qml.
        StyledRect {
            Layout.preferredWidth: Tokens.px(40)
            Layout.preferredHeight: Tokens.px(40)
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Auth.buffer.length ? (Colours.c.primary ?? Colours.c.onSurface) : "transparent"
            opacity: Auth.buffer.length ? 1 : 0.35

            Canvas {
                id: arrow
                anchors.centerIn: parent
                width: Tokens.px(22)
                height: Tokens.px(22)

                readonly property color stroke: Auth.buffer.length ? (Colours.c.onPrimary ?? Colours.c.surface) : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface)
                onStrokeChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    // Chevron authored on an 18x18 design grid, scaled to the
                    // canvas's actual (already Tokens.scale-adjusted) size so
                    // it stays centered and proportional at any panel scale.
                    const s = width / 18;
                    ctx.strokeStyle = stroke;
                    ctx.lineWidth = 2 * s;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(3 * s, 9 * s);
                    ctx.lineTo(15 * s, 9 * s);
                    ctx.moveTo(9.5 * s, 3.5 * s);
                    ctx.lineTo(15 * s, 9 * s);
                    ctx.lineTo(9.5 * s, 14.5 * s);
                    ctx.stroke();
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Auth.submit()
            }
        }
    }
}
