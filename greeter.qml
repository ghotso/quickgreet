//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.ui

// quickgreet — a Quickshell greeter for greetd.
//
// Two window modes:
//   production — a fullscreen layer-shell surface per monitor, with an
//                exclusive keyboard grab, because nothing else is running.
//   demo       — one ordinary window inside your existing session, so visuals
//                can be iterated on without touching greetd (QUICKGREET_DEMO=1).
ShellRoot {
    id: root

    // Instantiate the services up front rather than waiting for the first
    // binding to touch them: QML singletons are lazy, and their file/process
    // loads are async, so an early start means fewer visible pops on screen.
    Component.onCompleted: {
        void Config.appearance;
        void Colours.c;
        void Users.list;
        void Sessions.list;
        void Remember.lastUser;
        void Wallpaper.current;

        if (!DevMode.enabled && !Auth.available)
            console.warn("quickgreet: greetd socket unavailable — is this running under greetd?");
    }

    // ---- production: one layer-shell surface per screen ---------------------
    Variants {
        model: DevMode.enabled ? [] : Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickgreet"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            GreeterSurface {
                anchors.fill: parent
                focus: true
                // The card lives on the first screen; the rest just get the
                // wallpaper, so it isn't duplicated across monitors.
                primary: panel.modelData === Quickshell.screens[0]
            }
        }
    }

    // ---- demo: a single ordinary window ------------------------------------
    LazyLoader {
        active: DevMode.enabled

        FloatingWindow {
            title: "quickgreet (demo)"
            implicitWidth: 1600
            implicitHeight: 900
            color: "transparent"
            visible: true

            GreeterSurface {
                anchors.fill: parent
                focus: true
                primary: true
            }
        }
    }
}
