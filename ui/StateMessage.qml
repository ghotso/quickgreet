import QtQuick
import qs.components
import qs.config
import qs.services

// Transient status line under the password field.
//
// Errors flash and then clear themselves (Auth's 4s timer), so a stale "wrong
// password" never sits on screen misleading you. A Fatal — no greetd socket,
// no session to launch — deliberately does not auto-clear, and says how to get
// a terminal, because at that point the greeter can't log anyone in.
Item {
    id: root

    implicitHeight: Tokens.px(34)

    readonly property bool fatal: Auth.status === Auth.Status.Fatal

    StyledText {
        id: label

        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        elide: Text.ElideRight

        text: root.fatal ? `${Auth.message} — press Ctrl+Alt+F2 for a terminal` : Auth.message
        color: Auth.status === Auth.Status.None ? (Colours.c.onSurfaceVariant ?? Colours.c.onSurface) : (Colours.c.error ?? "#ff5555")
        font.pixelSize: Tokens.px(14)
        opacity: text.length ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.durations.defaultEffects
            }
        }
    }

    SequentialAnimation {
        id: flash
        running: false
        NumberAnimation {
            target: label
            property: "opacity"
            to: 0.25
            duration: 90
        }
        NumberAnimation {
            target: label
            property: "opacity"
            to: 1
            duration: 160
        }
    }

    Connections {
        target: Auth
        function onFlashMsg(): void {
            flash.restart();
        }
    }
}
