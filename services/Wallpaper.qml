pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Resolves the wallpaper to show behind the card.
//
// `wallpaperSource` may be either an image itself, or a pointer file whose
// contents are the absolute path to one (caelestia writes the latter, as
// state/caelestia/wallpaper/path.txt). Supporting both means a non-caelestia
// user can just point the config straight at a .png and be done.
Singleton {
    id: root

    readonly property string source: Config.expand(Config.appearance.wallpaperSource)
    readonly property string fallback: Config.expand(Config.appearance.wallpaperFallback)

    property string current: fallback

    readonly property bool isImage: /\.(png|jpe?g|webp|bmp|avif)$/i.test(source)

    function use(path: string): void {
        const p = (path ?? "").trim();
        root.current = p.length ? p : root.fallback;
    }

    FileView {
        // Only read the source as a pointer file when it isn't itself an image.
        path: root.isImage ? "" : root.source
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.use(text())
        onLoadFailed: {
            root.current = root.fallback;
            console.log(`quickgreet: no wallpaper pointer at ${root.source}`);
        }
    }

    Component.onCompleted: {
        if (isImage)
            root.current = source;
    }
}
