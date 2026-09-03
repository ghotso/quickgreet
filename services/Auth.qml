pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import qs.config

// The greetd conversation, wrapped in a small state machine the UI can bind to.
//
// Shape borrowed from caelestia's lock-screen Pam.qml: characters are buffered
// manually rather than living in a TextInput, a `status` enum drives the error
// display, `flashMsg` pulses it, and a timer clears the error after a few
// seconds. Only the backend differs — greetd instead of PAM directly.
Singleton {
    id: root

    enum Status {
        None,
        Failed,
        Fatal
    }

    // Mirrors GreetdState's numbering, so the same comparisons work against
    // both the real singleton and MockGreetd.
    readonly property int sInactive: 0
    readonly property int sAuthenticating: 1
    readonly property int sReadyToLaunch: 2
    readonly property int sLaunching: 3
    readonly property int sLaunched: 4

    readonly property var backend: DevMode.enabled ? MockGreetd : Greetd
    readonly property bool demo: DevMode.enabled

    // True when we can actually log someone in. In demo mode always true; in
    // production this is greetd's socket, and a false here is a hard failure
    // worth showing the user rather than silently pretending.
    readonly property bool available: backend?.available ?? false

    // Selection, driven by the UI.
    property string selectedUser: ""
    property var selectedSession: null

    // Typed characters. Cleared the moment they're handed to greetd.
    property string buffer: ""

    // Stashed at submit time: createSession() is async, so the password has to
    // survive until greetd actually asks for it.
    property string pendingResponse: ""
    property bool hasPending: false

    property int status: Auth.Status.None
    property string message: ""
    // Set from authMessage's echoResponse — an OTP prompt may want echo.
    property bool echo: false
    property string prompt: ""

    readonly property bool busy: backend?.state === sAuthenticating || backend?.state === sLaunching || backend?.state === sLaunched

    signal flashMsg

    function handleKey(event): void {
        if (busy && !echo)
            return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit();
        } else if (event.key === Qt.Key_Backspace) {
            buffer = (event.modifiers & Qt.ControlModifier) ? "" : buffer.slice(0, -1);
        } else if (event.key === Qt.Key_Escape) {
            clear();
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
            if (status !== Auth.Status.Fatal)
                status = Auth.Status.None;
        }
    }

    function submit(): void {
        if (!selectedUser) {
            fail("No user selected");
            return;
        }
        if (!available) {
            fatal("greetd is not available");
            return;
        }

        if (backend.state === sAuthenticating) {
            // A prompt is already live (second factor, or a re-prompt) —
            // answer it directly.
            backend.respond(buffer);
            buffer = "";
            return;
        }

        pendingResponse = buffer;
        hasPending = true;
        buffer = "";
        status = Auth.Status.None;
        backend.createSession(selectedUser);
    }

    function clear(): void {
        buffer = "";
        pendingResponse = "";
        hasPending = false;
    }

    function fail(msg: string): void {
        status = Auth.Status.Failed;
        message = msg;
        clear();
        flashMsg();
        resetTimer.restart();
    }

    function fatal(msg: string): void {
        status = Auth.Status.Fatal;
        message = msg;
        clear();
        flashMsg();
        console.warn(`quickgreet: ${msg}`);
    }

    function performLaunch(): void {
        const argv = Config.session.command?.length ? Config.session.command : Sessions.argv(selectedSession);

        if (!argv.length) {
            fatal("No session command to launch");
            return;
        }

        const env = (Config.session.environment ?? []).slice();
        if (selectedSession) {
            env.push(`XDG_SESSION_TYPE=${selectedSession.type === "x11" ? "x11" : "wayland"}`);
            if (selectedSession.id)
                env.push(`XDG_SESSION_DESKTOP=${selectedSession.id}`);
        }

        Remember.remember(selectedUser, selectedSession?.id ?? "");
        console.log(`quickgreet: launching ${JSON.stringify(argv)}`);
        backend.launch(argv, env, true);
    }

    Connections {
        target: root.backend

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (error) {
                root.message = message;
                root.status = Auth.Status.Failed;
                root.flashMsg();
                // greetd still expects an answer to a responseRequired message
                // even when it's flagged as an error; not answering wedges the
                // conversation.
                if (responseRequired)
                    root.backend.respond("");
                return;
            }

            if (!responseRequired) {
                // Informational (a MOTD, "password expires soon", ...).
                root.message = message;
                return;
            }

            root.prompt = message;
            root.echo = echoResponse;

            if (root.hasPending) {
                const answer = root.pendingResponse;
                root.pendingResponse = "";
                root.hasPending = false;
                root.backend.respond(answer);
            }
            // Otherwise this is a genuine extra prompt (2FA, OTP): leave it on
            // screen and wait for the user to type an answer.
        }

        function onAuthFailure(message: string): void {
            root.fail(message || "Authentication failed");
            // greetd tears the session down on failure; clear our side too so
            // the next Enter starts a fresh createSession().
            root.backend.cancelSession();
        }

        function onReadyToLaunch(): void {
            // A short, bounded gap between greetd saying "go" and quickgreet
            // actually handing off — gives the UI's exit transition (bound to
            // backend.state reaching sReadyToLaunch, see GreeterSurface.qml)
            // a moment to play before the real handoff happens. Bounded by a
            // Timer rather than anything the UI drives, so the handoff always
            // happens even if nothing is listening.
            launchTimer.restart();
        }

        function onError(message: string): void {
            root.fatal(message || "greetd error");
        }
    }

    Timer {
        id: launchTimer
        interval: 250
        onTriggered: root.performLaunch()
    }

    Timer {
        id: resetTimer
        interval: 4000
        onTriggered: {
            if (root.status === Auth.Status.Failed) {
                root.status = Auth.Status.None;
                root.message = "";
            }
        }
    }
}
