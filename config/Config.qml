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
                accentColor: null, // hex ("#rrggbb" or "rrggbb"), null = from palette
                radiusScale: 1, // multiplies Tokens.rounding.* — 0 sharp, 1 default
                avatarPath: "~/.face",
                avatarShape: "circle", // "circle" | "rounded" | "square" | "squircle"
                greeting: "",
                clockFormat: "HH:mm",
                dateFormat: "dddd • d MMM",
                clockTwoTone: true, // hour/minute in different palette colours
                passwordReveal: true, // hold-to-reveal button on the password field
                capsLockHint: false // opt-in: see README, "Caps Lock hint" caveats
            },
            behaviour: {
                showUserPicker: "auto", // "auto" | "always" | "never"
                showSessionPicker: "auto",
                rememberLastUser: true,
                rememberLastSession: true,
                minUid: 1000,
                maxUid: 60000,
                powerControls: ["suspend", "reboot", "poweroff"] // [] hides the row; unknown verbs are ignored
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

    // Resolved once at startup: is the avatar file actually there?
    //
    // Probed with `stat` rather than by letting the Image try and fail. Qt
    // logs `Cannot open: file://...` for a missing source, and since most
    // machines have no ~/.face — the case the initials fallback exists for —
    // that warning would fire on every greeter start, once per screen. Noise
    // is expensive here specifically: the journal is the only debugging
    // surface when a login screen misbehaves — so a plain "not found" stays
    // silent, but `stat`'s file-type output and stderr let us still warn
    // once for the two cases that ARE a real misconfiguration: the path
    // exists but isn't a regular file, or it exists but isn't readable by
    // this user (the same permissions trap documented in the README under
    // "Letting the greeter read your avatar").
    readonly property string avatarPath: expand(appearance.avatarPath)
    property bool avatarExists: false

    Process {
        id: avatarProbe

        running: root.avatarPath.length > 0
        command: ["stat", "-c", "%F", root.avatarPath]
        environment: ({ LC_ALL: "C", LANG: "C" })

        property string probeType: ""
        property string probeError: ""

        stdout: StdioCollector {
            onStreamFinished: avatarProbe.probeType = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: avatarProbe.probeError = text.trim()
        }

        onExited: code => {
            root.avatarExists = code === 0 && probeType === "regular file";
            if (code === 0 && !root.avatarExists)
                console.warn(`quickgreet: avatarPath "${root.avatarPath}" exists but is not a regular file (${probeType || "unknown"}) — ignoring it`);
            else if (code !== 0 && /Permission denied/.test(probeError))
                console.warn(`quickgreet: avatarPath "${root.avatarPath}" exists but is not readable by this user — check ownership/permissions (see README, "Letting the greeter read your avatar")`);
            // else: not found at all — the default, expected case on most
            // machines. Stay silent, same as before.
        }
    }

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
