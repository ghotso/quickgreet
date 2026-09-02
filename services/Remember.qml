pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Remembers the last user and session, so the common case is "type password,
// press Enter" rather than re-picking every boot.
//
// Lives under the *greeter* user's own state dir, which is always writable and
// needs no cross-user permission juggling — the same place tuigreet keeps its
// --remember state today.
//
// Named `Remember`, not `State`: QtQuick exports a `State` type, and the
// collision silently resolves to *that* rather than this singleton. It fails as
// "Property 'remember' of object QtQuick/State is not a function" — and only on
// the success path, i.e. you'd discover it by being unable to log in.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_STATE_HOME") || `${Config.home}/.local/state`) + "/quickgreet"
    readonly property string path: `${dir}/last.json`

    property string lastUser: ""
    property string lastSession: ""

    function remember(user: string, session: string): void {
        if (Config.behaviour.rememberLastUser)
            root.lastUser = user ?? "";
        if (Config.behaviour.rememberLastSession)
            root.lastSession = session ?? "";

        if (!Config.behaviour.rememberLastUser && !Config.behaviour.rememberLastSession)
            return;

        // Best-effort: never let a failed write block a login.
        try {
            view.setText(JSON.stringify({
                user: root.lastUser,
                session: root.lastSession
            }, null, 2));
        } catch (e) {
            console.warn(`quickgreet: could not save state to ${root.path} (${e})`);
        }
    }

    FileView {
        id: view

        path: root.path
        printErrors: false
        atomicWrites: true

        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.lastUser = s.user ?? "";
                root.lastSession = s.session ?? "";
            } catch (e) {
                console.warn(`quickgreet: ignoring malformed ${root.path}`);
            }
        }

        onLoadFailed: {} // first run — nothing remembered yet, which is fine
    }
}
