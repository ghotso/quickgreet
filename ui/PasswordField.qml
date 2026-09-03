import QtQuick
import QtQuick.Layouts
import Quickshell
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
    // True only while the reveal button is physically held down — binding
    // straight to MouseArea.pressed rather than hand-rolled press/release
    // booleans gets drag-off/cancel handling for free.
    readonly property bool revealing: revealMouse.pressed

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

            // A real ListView over the actual characters, not a bare count —
            // that's what lets a specific dot animate itself out on
            // backspace instead of the row just shrinking.
            ListView {
                anchors.verticalCenter: parent.verticalCenter
                visible: Auth.buffer.length && !Auth.echo && !root.revealing
                orientation: ListView.Horizontal
                interactive: false
                width: contentWidth
                height: Tokens.px(8)
                spacing: Tokens.px(7)

                model: ScriptModel {
                    // First 24 characters — the same saturating cap the old
                    // Math.min(length, 24) count gave: past that, further
                    // keystrokes neither add nor animate a new dot until you
                    // backspace back under it.
                    values: Auth.buffer.slice(0, 24).split("")
                }

                delegate: Item {
                    id: dot

                    required property int index

                    implicitWidth: Tokens.px(8)
                    implicitHeight: Tokens.px(8)

                    // Alternates between the two dot shapes the greeter
                    // already draws elsewhere (a plain circle, and the
                    // squircle built for the avatar option), so a run of
                    // typed characters doesn't read as one repeated glyph.
                    readonly property bool squircle: index % 2 === 1

                    StyledRect {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colours.c.onSurface
                        visible: !dot.squircle
                    }
                    Squircle {
                        anchors.fill: parent
                        color: Colours.c.onSurface
                        visible: dot.squircle
                    }

                    // Pops in exactly as the old per-count dot did — the
                    // Spatial easing already overshoots past 1 before
                    // settling, which is what reads as a bounce.
                    scale: 0
                    opacity: 0
                    Component.onCompleted: {
                        scale = 1;
                        opacity = 1;
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.Type.Spatial
                            duration: Tokens.durations.fastEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.Type.Effects
                        }
                    }

                    // Backspace previously just shrank the row; a specific
                    // dot now fades and shrinks itself out, held alive by
                    // ListView.delayRemove until that finishes.
                    ListView.onRemove: removeAnim.start()

                    SequentialAnimation {
                        id: removeAnim
                        PropertyAction {
                            target: dot
                            property: "ListView.delayRemove"
                            value: true
                        }
                        ParallelAnimation {
                            Anim {
                                target: dot
                                property: "opacity"
                                to: 0
                                type: Anim.Type.Effects
                            }
                            Anim {
                                target: dot
                                property: "scale"
                                to: 0.5
                                type: Anim.Type.Effects
                            }
                        }
                        PropertyAction {
                            target: dot
                            property: "ListView.delayRemove"
                            value: false
                        }
                    }
                }
            }

            // Held-down plaintext reveal. Auth.buffer is already safe to bind
            // directly — handleKey() strips control characters before they
            // ever reach it, same as the OTP echo case above.
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: Auth.buffer.length && !Auth.echo && root.revealing
                text: Auth.buffer
                font.pixelSize: Tokens.px(16)
            }
        }

        // Hold-to-reveal. Hidden entirely once the config opts out, and on an
        // already-echoed prompt (OTP, say) where the text is in clear anyway.
        StyledRect {
            Layout.preferredWidth: Tokens.px(32)
            Layout.preferredHeight: Tokens.px(32)
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: "transparent"
            visible: Config.appearance.passwordReveal && Auth.buffer.length > 0 && !Auth.echo

            Canvas {
                id: eye
                anchors.centerIn: parent
                width: Tokens.px(20)
                height: Tokens.px(20)

                readonly property color stroke: root.revealing ? (Colours.c.primary ?? Colours.c.onSurface) : (Colours.c.onSurfaceVariant ?? Colours.c.onSurface)
                onStrokeChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                // Eye glyph on a 20x20 design grid — same hand-drawn approach
                // as the submit chevron, so no icon-font dependency.
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const s = width / 20;
                    ctx.strokeStyle = stroke;
                    ctx.lineWidth = 1.6 * s;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    ctx.beginPath();
                    ctx.moveTo(2 * s, 10 * s);
                    ctx.quadraticCurveTo(10 * s, 2 * s, 18 * s, 10 * s);
                    ctx.quadraticCurveTo(10 * s, 18 * s, 2 * s, 10 * s);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.arc(10 * s, 10 * s, 2.6 * s, 0, Math.PI * 2);
                    ctx.stroke();
                }
            }

            MouseArea {
                id: revealMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Submit affordance. Drawn, not a font glyph — see Avatar.qml.
        StyledRect {
            id: submitBtn

            Layout.preferredWidth: Tokens.px(40)
            Layout.preferredHeight: Tokens.px(40)
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Auth.buffer.length ? (Colours.c.primary ?? Colours.c.onSurface) : "transparent"
            // Hovering an empty field nudges opacity up as a "you can click
            // here" affordance; pressing either state scales it down slightly.
            opacity: Auth.buffer.length ? 1 : (submitMouse.containsMouse ? 0.5 : 0.35)
            scale: submitMouse.pressed ? 0.9 : (submitMouse.containsMouse ? 1.06 : 1)

            Behavior on opacity {
                Anim {
                    type: Anim.Type.Effects
                }
            }
            Behavior on scale {
                Anim {
                    type: Anim.Type.Effects
                }
            }

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
                id: submitMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Auth.submit()
            }
        }
    }
}
