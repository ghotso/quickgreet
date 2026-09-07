pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Suspend / reboot / power off, run via systemctl through logind's
// allow_active policy — the greeter's session is the active one on the seat
// while it's shown, so these succeed with no polkit rule (see issue #1).
//
// Demo mode must NEVER actually run these: a power button wired straight to
// `systemctl poweroff` would shut down the machine you're iterating on the
// first time anyone clicked it. `run()` logs the argv it would have used and
// stops there instead, the same shape MockGreetd.launch() uses for launch().
Singleton {
    id: root

    // No logout (nobody is logged in at a greeter) and no hibernate (needs
    // swap sized for it, fails confusingly when there isn't any).
    readonly property var verbs: [
        { name: "suspend", label: "Suspend", confirm: false, argv: ["systemctl", "suspend"] },
        { name: "reboot", label: "Restart", confirm: true, argv: ["systemctl", "reboot"] },
        { name: "poweroff", label: "Power Off", confirm: true, argv: ["systemctl", "poweroff"] }
    ]

    // behaviour.powerControls names which verbs to offer; canonical order
    // above is kept regardless of the config list's own order. A malformed
    // value (not a list) or an unrecognised verb name is dropped with a
    // warning rather than taking the greeter down — same shape as
    // Users.toUid's defence against a typo'd minUid/maxUid.
    readonly property var enabled: {
        const raw = Config.behaviour.powerControls;
        if (!Array.isArray(raw)) {
            console.warn(`quickgreet: behaviour.powerControls is not a list — hiding power controls`);
            return [];
        }
        for (const name of raw)
            if (!root.verbs.some(v => v.name === name))
                console.warn(`quickgreet: behaviour.powerControls has unknown verb "${name}" — ignoring it`);
        return root.verbs.filter(v => raw.includes(v.name));
    }

    signal actionFailed(string message)

    function run(name: string): void {
        const v = root.verbs.find(x => x.name === name);
        if (!v) {
            console.warn(`quickgreet: unknown power verb "${name}"`);
            return;
        }

        if (DevMode.enabled) {
            console.log(`quickgreet[demo]: would run ${JSON.stringify(v.argv)}`);
            return;
        }

        proc.label = v.label;
        proc.errorText = "";
        proc.startedOk = false;
        proc.exec(v.argv);
    }

    Process {
        id: proc

        property string label: ""
        property string errorText: ""
        // exec() on a missing binary never reaches onExited — QProcess fails
        // to start and `running` goes straight to (a no-op) false instead of
        // ever having been true. Tracking the true transition is the only
        // reliable way to tell "ran and exited" from "never started" apart.
        property bool startedOk: false

        stderr: StdioCollector {
            onStreamFinished: proc.errorText = text.trim()
        }

        onRunningChanged: {
            if (proc.running) {
                proc.startedOk = true;
            } else if (!proc.startedOk) {
                root.actionFailed(`${proc.label} failed — is systemctl installed?`);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.actionFailed(`${proc.label} failed${proc.errorText ? `: ${proc.errorText}` : ` (exit code ${exitCode})`}`);
        }
    }
}
