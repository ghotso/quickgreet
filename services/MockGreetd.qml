pragma Singleton

import QtQuick
import Quickshell
import qs.config

// A stand-in for Quickshell.Services.Greetd, used only in demo mode.
//
// Mirrors the real singleton's property/signal/method surface exactly so
// Auth.qml can bind to either without knowing which it has. State values match
// GreetdState's numbering.
Singleton {
    id: root

    readonly property int stateInactive: 0
    readonly property int stateAuthenticating: 1
    readonly property int stateReadyToLaunch: 2
    readonly property int stateLaunching: 3
    readonly property int stateLaunched: 4

    readonly property bool available: true
    property int state: stateInactive
    property string user: ""

    signal authMessage(string message, bool error, bool responseRequired, bool echoResponse)
    signal authFailure(string message)
    signal readyToLaunch
    signal launched
    signal error(string message)

    property string pending: ""

    function createSession(who: string): void {
        root.user = who;
        root.state = root.stateAuthenticating;
        promptTimer.restart();
    }

    function cancelSession(): void {
        promptTimer.stop();
        resultTimer.stop();
        root.state = root.stateInactive;
        root.user = "";
    }

    function respond(response: string): void {
        root.pending = response;
        resultTimer.restart();
    }

    // In demo mode a "launch" must NOT quit — that would kill the window you're
    // iterating in. Log the resolved argv and reset so you can try again.
    function launch(command: var, environment: var, quit: bool): void {
        console.log(`quickgreet[demo]: would launch ${JSON.stringify(command)} env=${JSON.stringify(environment)} quit=${quit}`);
        root.state = root.stateLaunched;
        root.launched();
        resetTimer.restart();
    }

    Timer {
        id: promptTimer
        interval: Math.max(50, Config.dev.mockDelayMs / 2)
        onTriggered: root.authMessage("Password:", false, true, false)
    }

    Timer {
        id: resultTimer
        interval: Config.dev.mockDelayMs
        onTriggered: {
            if (root.pending === Config.dev.mockPassword) {
                root.state = root.stateReadyToLaunch;
                root.readyToLaunch();
            } else {
                root.state = root.stateInactive;
                root.authFailure("Authentication failed");
            }
            root.pending = "";
        }
    }

    Timer {
        id: resetTimer
        interval: 1200
        onTriggered: {
            root.state = root.stateInactive;
            root.user = "";
        }
    }
}
