// Headless test of the auth state machine against MockGreetd.
//
//   QUICKGREET_DEMO=1 qs -p test-auth-flow.qml
//
// Lives at the repo root, not in tests/, because Quickshell resolves the qs.*
// import namespace relative to the entrypoint file's own directory — from
// tests/ it would look for tests/services and find nothing.
//
// Exercises the paths that are genuinely risky to get wrong and miserable to
// debug live on a TTY: buffering, the async gap between createSession() and
// the password prompt actually arriving, failure recovery, and resolving the
// session argv that gets launched.

import QtQuick
import Quickshell
import qs.config
import qs.services

ShellRoot {
    id: root

    property int passed: 0
    property int failed: 0
    property var launchedArgv: null

    function check(name: string, cond: bool, detail: string): void {
        if (cond) {
            root.passed++;
            console.log(`  PASS  ${name}`);
        } else {
            root.failed++;
            console.log(`  FAIL  ${name}${detail ? ` — ${detail}` : ""}`);
        }
    }

    function type(text: string): void {
        for (const ch of text)
            Auth.handleKey({
                key: 0,
                text: ch,
                modifiers: 0
            });
    }

    function press(key: int): void {
        Auth.handleKey({
            key: key,
            text: "",
            modifiers: 0
        });
    }

    Connections {
        target: Auth.backend
        function onLaunched(): void {
            // MockGreetd logs the argv; capture what Auth resolved.
            root.launchedArgv = Auth.selectedSession ? Sessions.argv(Auth.selectedSession) : null;
        }
    }

    Component.onCompleted: {
        void Users.list;
        void Sessions.list;
        console.log("\nquickgreet auth-flow tests");
    }

    // Sequenced with timers because the mock backend deliberately answers
    // asynchronously, exactly as greetd does.
    Timer {
        running: true
        interval: 1500
        onTriggered: {
            check("demo mode active", Auth.demo, "set QUICKGREET_DEMO=1");
            check("backend available", Auth.available, "");
            check("users discovered", Users.list.length > 0, "");
            check("sessions discovered", Sessions.list.length > 0, "");

            Auth.selectedUser = Users.list[0]?.name ?? "";
            Auth.selectedSession = Sessions.list[0] ?? null;

            // --- typing and editing ---
            root.type("abc");
            check("buffer accumulates", Auth.buffer === "abc", `got '${Auth.buffer}'`);
            press(Qt.Key_Backspace);
            check("backspace removes one", Auth.buffer === "ab", `got '${Auth.buffer}'`);
            press(Qt.Key_Escape);
            check("escape clears", Auth.buffer === "", `got '${Auth.buffer}'`);

            // --- wrong password ---
            root.type("definitely-wrong");
            press(Qt.Key_Return);
            check("buffer stashed on submit", Auth.buffer === "" && Auth.hasPending, "password must survive the async gap");
            wrongCheck.restart();
        }
    }

    Timer {
        id: wrongCheck
        interval: 1600
        onTriggered: {
            check("wrong password fails", Auth.status === Auth.Status.Failed, `status=${Auth.status}`);
            check("failure clears buffer", Auth.buffer === "" && !Auth.hasPending, "");
            check("failure surfaces a message", Auth.message.length > 0, "");

            // --- correct password, after a failure ---
            root.type(Config.dev.mockPassword);
            press(Qt.Key_Return);
            rightCheck.restart();
        }
    }

    Timer {
        id: rightCheck
        interval: 1600
        onTriggered: {
            check("correct password launches", root.launchedArgv !== null, "readyToLaunch never fired");
            check("launch argv resolved", (root.launchedArgv?.length ?? 0) > 0, `argv=${JSON.stringify(root.launchedArgv)}`);

            console.log(`\n${root.failed === 0 ? "ALL PASSED" : "FAILURES"}: ${root.passed} passed, ${root.failed} failed\n`);
            Qt.exit(root.failed === 0 ? 0 : 1);
        }
    }
}
