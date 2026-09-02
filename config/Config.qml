pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Loads /etc/quickgreet/config.json (override with $QUICKGREET_CONFIG).
//
// Every key is optional. A missing or malformed file is not an error — it logs
// once and every default below applies. A greeter that refuses to start because
// its config has a typo is a greeter that locks you out of your machine.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || "/var/lib/greetd"

    readonly property string configPath: Quickshell.env("QUICKGREET_CONFIG") || "/etc/quickgreet/config.json"

    // Expands a leading ~ and $HOME. Paths in the config are written from the
    // perspective of the user the greeter runs as (`greeter` in production).
    function expand(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("~/"))
            return root.home + path.slice(1);
        if (path === "~")
            return root.home;
        return path.replace(/^\$HOME/, root.home).replace(/^\$\{HOME\}/, root.home);
    }

    // ---- defaults ----------------------------------------------------------

    readonly property var defaults: ({
            session: {
                command: null, // null => use the selected .desktop session's Exec
                environment: []
            },
            appearance: {
                paletteSource: "~/.local/state/caelestia/scheme.json",
                wallpaperSource: "~/.local/state/caelestia/wallpaper/path.txt",
                wallpaperFallback: "",
                blurWallpaper: true,
                blurAmount: 24,
                dim: 0.22,
                avatarPath: "~/.face",
                greeting: "",
                clockFormat: "HH:mm",
                dateFormat: "dddd • d MMM"
            },
            behaviour: {
                showUserPicker: "auto", // "auto" | "always" | "never"
                showSessionPicker: "auto",
                rememberLastUser: true,
                rememberLastSession: true,
                minUid: 1000,
                maxUid: 60000
            },
            dev: {
                mockPassword: "test",
                mockDelayMs: 600,
                // Demo mode only. When non-empty, these replace the real
                // /etc/passwd users — which keeps demo runs reproducible on
                // any machine, and keeps a contributor's actual name and
                // username out of screenshots.
                // e.g. [{ "name": "alex", "gecos": "Alex Morgan", "uid": 1000 }]
                mockUsers: []
            }
        })

    property var loaded: ({})

    // Section accessors — merged shallowly over the defaults, so a config that
    // sets one key in a section doesn't wipe the rest of it.
    readonly property var session: merge(defaults.session, loaded.session)
    readonly property var appearance: merge(defaults.appearance, loaded.appearance)
    readonly property var behaviour: merge(defaults.behaviour, loaded.behaviour ?? loaded.behavior)
    readonly property var dev: merge(defaults.dev, loaded.dev)

    function merge(base: var, over: var): var {
        const out = Object.assign({}, base);
        if (over && typeof over === "object")
            for (const k of Object.keys(over))
                if (over[k] !== null && over[k] !== undefined)
                    out[k] = over[k];
        return out;
    }

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                root.loaded = (parsed && typeof parsed === "object") ? parsed : {};
                console.log(`quickgreet: loaded config from ${root.configPath}`);
            } catch (e) {
                root.loaded = {};
                console.warn(`quickgreet: ${root.configPath} is not valid JSON (${e}) — using defaults`);
            }
        }

        onLoadFailed: {
            root.loaded = {};
            console.log(`quickgreet: no config at ${root.configPath} — using defaults`);
        }
    }
}
