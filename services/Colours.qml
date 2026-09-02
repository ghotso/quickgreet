pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Material You palette, read as *data* from a scheme.json file.
//
// This is quickgreet's only coupling to caelestia, and it is deliberately a
// file format rather than a code dependency: nothing here imports caelestia
// QML, so an upstream refactor there cannot break this greeter.
//
// Expected shape (hex values WITHOUT a leading '#'):
//   { "name": "...", "flavour": "...", "mode": "dark"|"light", "variant": "...",
//     "colours": { "primary": "f4d878", "surface": "0e1a14", ... } }
//
// Any Material 3 role name may appear; they are mapped generically, so a
// palette with more or fewer roles than expected still works. Absent or
// malformed file => the built-in palette below.
Singleton {
    id: root

    readonly property string path: Config.expand(Config.appearance.paletteSource)

    property string schemeName: "quickgreet-default"
    property string flavour: "default"
    property bool light: false

    // A neutral dark Material palette, used when no scheme file is readable.
    // Intentionally not caelestia's colours — quickgreet should look
    // deliberate out of the box for someone who has never heard of caelestia.
    readonly property var fallback: ({
            background: "#12131a",
            onBackground: "#e4e1e9",
            surface: "#12131a",
            surfaceDim: "#0d0e14",
            surfaceBright: "#1e1f27",
            surfaceContainerLowest: "#08090e",
            surfaceContainerLow: "#171821",
            surfaceContainer: "#1b1c25",
            surfaceContainerHigh: "#262731",
            surfaceContainerHighest: "#31323c",
            onSurface: "#e4e1e9",
            surfaceVariant: "#46464f",
            onSurfaceVariant: "#c7c5d0",
            outline: "#91909a",
            outlineVariant: "#46464f",
            shadow: "#000000",
            scrim: "#000000",
            primary: "#bfc2ff",
            onPrimary: "#242a60",
            primaryContainer: "#3b4178",
            onPrimaryContainer: "#e0e0ff",
            secondary: "#c4c5dd",
            onSecondary: "#2d2f42",
            error: "#ffb4ab",
            onError: "#690005",
            errorContainer: "#93000a",
            onErrorContainer: "#ffdad6"
        })

    // The live palette. Bindings read `Colours.c.<role>`; assigning a whole new
    // object on reload is what makes those bindings re-evaluate.
    //
    // Named `Colours`, not `Palette`: QtQuick already exports a `Palette` type
    // and the collision silently shadows this singleton instead of erroring —
    // properties just come back `undefined`, which is a miserable thing to debug.
    property var c: fallback

    function load(data: string): void {
        const scheme = JSON.parse(data);
        if (!scheme || typeof scheme.colours !== "object")
            throw new Error("missing 'colours' object");

        // Start from the fallback so a partial scheme still has every role the
        // UI might reference, rather than rendering transparent holes.
        const next = Object.assign({}, root.fallback);
        for (const [name, hex] of Object.entries(scheme.colours)) {
            if (typeof hex === "string" && hex.length)
                next[name] = hex.startsWith("#") ? hex : `#${hex}`;
        }

        root.c = next;
        root.schemeName = scheme.name ?? "unknown";
        root.flavour = scheme.flavour ?? "default";
        root.light = scheme.mode === "light";
    }

    function useFallback(reason: string): void {
        root.c = root.fallback;
        root.schemeName = "quickgreet-default";
        root.light = false;
        console.log(`quickgreet: ${reason} — using built-in palette`);
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            try {
                root.load(text());
                console.log(`quickgreet: palette '${root.schemeName}' loaded from ${root.path}`);
            } catch (e) {
                root.useFallback(`could not parse ${root.path} (${e})`);
            }
        }

        onLoadFailed: root.useFallback(`no palette at ${root.path}`)
    }
}
