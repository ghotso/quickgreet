pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Best-effort Caps Lock tracking. Opt-in (appearance.capsLockHint) because it
// has a real blind spot — see below.
//
// There is no portable Qt/QML property for lock-key state, so `active` is
// tracked locally from Qt.Key_CapsLock presses seen while the greeter has
// keyboard focus (see GreeterSurface.qml's Keys.onPressed). That means it
// starts out only a guess: if Caps Lock was already on before the greeter's
// exclusive keyboard grab began, tracking starts wrong and stays wrong until
// the next press — which flips it, but from a false starting point, so it's
// then *also* wrong. A best-effort Hyprland probe (`hyprctl -j devices`)
// seeds the initial state correctly on a Hyprland greeter session; on
// sway/cage, or if hyprctl fails, tracking still starts, just unseeded.
//
// `confident` gates whether the hint is shown at all, and the UI must only
// ever render it when `active` is also true — asserting "Caps Lock is off"
// from a guess would be actively worse than showing nothing, since this
// exists specifically to explain a failed login.
Singleton {
    id: root

    property bool active: false
    property bool confident: false

    function handleKey(event): void {
        if (event.key === Qt.Key_CapsLock) {
            root.active = !root.active;
            root.confident = true;
        }
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const kbs = data.keyboards ?? [];
                    const kb = kbs.find(k => k.main) ?? kbs.find(k => "capsLock" in k);
                    if (kb) {
                        root.active = !!kb.capsLock;
                        root.confident = true;
                    }
                } catch (e) {
                    // Not Hyprland, or an incompatible hyprctl — stay unseeded,
                    // tracking still works from here via handleKey().
                }
            }
        }
    }
}
