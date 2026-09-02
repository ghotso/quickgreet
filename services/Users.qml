pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Human users, read straight from /etc/passwd.
//
// Deliberately NOT accountsservice: that needs a running system D-Bus and
// accounts-daemon before the greeter's compositor even starts. /etc/passwd is
// always there, world-readable, needs no IPC, and has no startup ordering to
// get wrong — which is what you want in the one process standing between you
// and your machine.
Singleton {
    id: root

    // [{ name, uid, gecos, home, shell }]
    property var list: []
    readonly property bool multiple: list.length > 1

    // Demo mode may substitute a fixed user list, so demo runs don't depend on
    // (or expose) whoever happens to have an account on the machine.
    readonly property var mocked: DevMode.enabled ? (Config.dev.mockUsers ?? []) : []

    function parse(passwd: string): void {
        if (root.mocked.length) {
            root.list = root.mocked;
            console.log(`quickgreet[demo]: using ${root.mocked.length} mock user(s)`);
            return;
        }

        const min = Config.behaviour.minUid;
        const max = Config.behaviour.maxUid;
        const out = [];

        for (const line of passwd.split("\n")) {
            if (!line || line.startsWith("#"))
                continue;
            const f = line.split(":");
            if (f.length < 7)
                continue;

            const uid = parseInt(f[2]);
            if (isNaN(uid) || uid < min || uid >= max)
                continue;

            // Accounts that cannot log in shouldn't be offered as logins.
            const shell = f[6];
            if (/(nologin|\/false)$/.test(shell))
                continue;

            out.push({
                name: f[0],
                uid: uid,
                // GECOS full name, minus the trailing room/phone commas
                gecos: (f[4] || "").split(",")[0].trim(),
                home: f[5],
                shell: shell
            });
        }

        out.sort((a, b) => a.uid - b.uid);
        root.list = out;
        console.log(`quickgreet: found ${out.length} user(s): ${out.map(u => u.name).join(", ")}`);
    }

    function displayName(user: var): string {
        return user?.gecos || user?.name || "";
    }

    FileView {
        path: "/etc/passwd"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: console.warn("quickgreet: could not read /etc/passwd — no users to offer")
    }
}
