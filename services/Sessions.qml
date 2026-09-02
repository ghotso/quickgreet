pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Enumerates installed desktop sessions from the freedesktop session dirs.
//
// Read via one `sh` invocation rather than FolderListModel + a fan-out of
// FileViews: a greeter reads this once at startup, and one process with an
// obvious output format is far easier to debug at 3am on a TTY than a tree of
// async QML file loads.
Singleton {
    id: root

    // [{ id, name, exec, type: "wayland"|"x11", path }]
    property var list: []
    readonly property bool multiple: list.length > 1

    readonly property var waylandDir: "/usr/share/wayland-sessions"
    readonly property var xDir: "/usr/share/xsessions"

    function parse(dump: string): void {
        const out = [];
        // Records are separated by a line of the form ===<type>\t<path>.
        // The leading "\n" matters: without it the very first record (which
        // starts at offset 0, with no newline before it) is silently dropped.
        for (const chunk of `\n${dump}`.split("\n===").slice(1)) {
            const nl = chunk.indexOf("\n");
            if (nl < 0)
                continue;
            const [type, path] = chunk.slice(0, nl).split("\t");
            const body = chunk.slice(nl + 1);

            const field = name => {
                // Only match keys at line start, unlocalised (skip Name[de]=)
                const m = body.match(new RegExp(`^${name}=(.*)$`, "m"));
                return m ? m[1].trim() : "";
            };

            if (field("Hidden").toLowerCase() === "true")
                continue;
            if (field("NoDisplay").toLowerCase() === "true")
                continue;

            const exec = field("Exec");
            if (!exec)
                continue;

            out.push({
                id: path.split("/").pop().replace(/\.desktop$/, ""),
                name: field("Name") || path.split("/").pop().replace(/\.desktop$/, ""),
                exec: exec,
                type: type,
                path: path
            });
        }

        // Wayland first, then alphabetical — the common case on this kind of
        // system is a single wayland session, and it should be the default.
        out.sort((a, b) => a.type === b.type ? a.name.localeCompare(b.name) : (a.type === "wayland" ? -1 : 1));
        root.list = out;
        console.log(`quickgreet: found ${out.length} session(s): ${out.map(s => s.id).join(", ")}`);
    }

    // Turns a desktop-entry Exec= into an argv array, dropping the %f/%U style
    // field codes that are meaningless for a session command.
    function argv(session: var): var {
        if (!session?.exec)
            return [];
        return session.exec.split(/\s+/).filter(a => a.length && !/^%[fFuUdDnNickvm]$/.test(a));
    }

    // Plain (non-template) string on purpose: QML template literals mangle the
    // backslash escapes printf needs. Dirs come in as positional args.
    readonly property string dumpScript: "emit() { [ -d \"$2\" ] || return 0; for f in \"$2\"/*.desktop; do [ -f \"$f\" ] || continue; printf '===%s\\t%s\\n' \"$1\" \"$f\"; cat \"$f\"; printf '\\n'; done; }; emit wayland \"$1\"; emit x11 \"$2\""

    Process {
        running: true
        command: ["sh", "-c", root.dumpScript, "sh", root.waylandDir, root.xDir]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
