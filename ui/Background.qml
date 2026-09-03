import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

// Wallpaper, blurred, over a palette-coloured base.
//
// The base colour matters: it's what shows while the image loads, and what you
// get if there's no readable wallpaper at all. A greeter should never flash
// black or, worse, transparent.
Item {
    id: root

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Colours.c.surfaceDim ?? Colours.c.surface
            }
            GradientStop {
                position: 1
                color: Colours.c.surfaceContainer ?? Colours.c.surface
            }
        }
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: Wallpaper.current ? `file://${Wallpaper.current}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
        onStatusChanged: {
            if (status === Image.Error)
                console.warn(`quickgreet: could not load wallpaper ${Wallpaper.current}`);
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: Config.appearance.blurWallpaper && Config.appearance.blurAmount > 0
        blur: 1
        // Clamped rather than passed straight through: a negative/garbage
        // config value shouldn't reach MultiEffect, and a very high one is
        // expensive precisely where it's most likely to be paid — greeter
        // sessions often run on unaccelerated software rendering.
        blurMax: Math.max(0, Math.min(128, Config.appearance.blurAmount))
        blurMultiplier: 1
        opacity: wallpaper.status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.easing.standard
            }
        }
    }

    // Scrim: keeps the card legible over a bright or busy wallpaper. Tunable,
    // because how much dimming a wallpaper needs is entirely a property of the
    // wallpaper — a washed-out photo wants more, a dark graphic wants none.
    Rectangle {
        anchors.fill: parent
        color: Colours.c.scrim ?? "#000000"
        opacity: Config.appearance.dim
    }
}
