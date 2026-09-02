import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.components
import qs.config
import qs.services
import "pickers"

// The login side of the two-pane layout: everything you actually interact with,
// contained in a single surface so it reads as one object against the wallpaper.
StyledRect {
    id: root

    property int userIndex: 0
    property int sessionIndex: 0

    readonly property var user: Users.list[userIndex] ?? null
    readonly property var session: Sessions.list[sessionIndex] ?? null

    function shouldShow(mode: string, many: bool): bool {
        if (mode === "always")
            return true;
        if (mode === "never")
            return false;
        return many;
    }

    readonly property bool showUsers: shouldShow(Config.behaviour.showUserPicker, Users.multiple)
    readonly property bool showSessions: shouldShow(Config.behaviour.showSessionPicker, Sessions.multiple)

    implicitWidth: Tokens.px(Tokens.sizes.cardWidth)
    implicitHeight: layout.implicitHeight + Tokens.px(Tokens.padding.extraLarge) * 2

    radius: Tokens.px(Tokens.rounding.extraLarge * 1.5)
    color: Colours.c.surface
    opacity: 0.97

    // Restore the remembered selection once the lists have loaded. Both are
    // async, so this runs on change rather than only at construction.
    function restore(): void {
        if (Remember.lastUser) {
            const u = Users.list.findIndex(x => x.name === Remember.lastUser);
            if (u >= 0)
                root.userIndex = u;
        }
        if (Remember.lastSession) {
            const s = Sessions.list.findIndex(x => x.id === Remember.lastSession);
            if (s >= 0)
                root.sessionIndex = s;
        }
    }

    Connections {
        target: Users
        function onListChanged(): void {
            root.restore();
        }
    }

    Connections {
        target: Sessions
        function onListChanged(): void {
            root.restore();
        }
    }

    onUserChanged: Auth.selectedUser = user?.name ?? ""
    onSessionChanged: Auth.selectedSession = session

    Component.onCompleted: {
        restore();
        Auth.selectedUser = user?.name ?? "";
        Auth.selectedSession = session;
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        width: parent.width - Tokens.px(Tokens.padding.extraLarge) * 2
        spacing: Tokens.px(Tokens.spacing.large)

        Avatar {
            Layout.alignment: Qt.AlignHCenter
            user: root.user?.name ?? ""
            displayName: Users.displayName(root.user)
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Users.displayName(root.user) || root.user?.name || "No user available"
            font.pixelSize: Tokens.px(21)
            font.weight: Font.Medium
        }

        Picker {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            visible: root.showUsers
            model: Users.list
            currentIndex: root.userIndex
            labelFor: u => u.name
            onSelected: i => root.userIndex = i
        }

        PasswordField {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.px(Tokens.spacing.extraSmall)
        }

        StateMessage {
            Layout.fillWidth: true
        }

        Picker {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            visible: root.showSessions
            model: Sessions.list
            currentIndex: root.sessionIndex
            labelFor: s => s.name
            onSelected: i => root.sessionIndex = i
        }
    }
}
