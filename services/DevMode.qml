pragma Singleton

import QtQuick
import Quickshell

// Demo/development mode.
//
// Triggered ONLY by an explicit QUICKGREET_DEMO=1. It is deliberately *not*
// inferred from `Greetd.available === false`, even though that would be
// convenient: if a real rollout is broken and greetd's socket is missing, you
// want a loud "no greetd socket" error, not a silently-successful fake login
// that hides the bug until you're locked out.
Singleton {
    id: root

    readonly property bool enabled: Quickshell.env("QUICKGREET_DEMO") === "1"
}
