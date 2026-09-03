pragma Singleton

import QtQuick
import Quickshell

// Design tokens. Deliberately a plain QML singleton rather than a dependency on
// caelestia's compiled Caelestia.Config plugin — these are just numbers, and
// duplicating them here is what keeps quickgreet standalone.
Singleton {
    id: root

    // UI scale, set from the greeter surface based on screen height.
    //
    // This matters more than it looks: greeters commonly run on an unscaled
    // 4K panel (the compositor hosting them has no per-output scale config to
    // inherit), where fixed pixel sizes render comically small. Everything
    // visual goes through px() so the whole design tracks the panel.
    property real scale: 1

    function px(v: real): int {
        return Math.round(v * root.scale);
    }

    readonly property QtObject rounding: QtObject {
        // Multiplies every value below. Not named `scale` — that's
        // Tokens.scale above, the unrelated panel-DPI factor.
        readonly property real factor: Math.max(0, Config.appearance.radiusScale)

        readonly property int small: Math.round(8 * factor)
        readonly property int normal: Math.round(12 * factor)
        readonly property int large: Math.round(20 * factor)
        readonly property int extraLarge: Math.round(28 * factor)
        readonly property int full: 1000 // unscaled sentinel, not currently read anywhere
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int normal: 12
        readonly property int large: 18
        readonly property int extraLarge: 24
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int normal: 12
        readonly property int large: 18
        readonly property int extraLarge: 24
    }

    readonly property QtObject durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int fastSpatial: 350
        readonly property int defaultSpatial: 500
        readonly property int slowSpatial: 650
        readonly property int fastEffects: 150
        readonly property int defaultEffects: 200
        readonly property int slowEffects: 300
    }

    // Cubic-bezier control points, in the [x1, y1, x2, y2, 1, 1] form
    // Easing.BezierSpline expects.
    readonly property QtObject easing: QtObject {
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> expressiveSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    }

    readonly property QtObject font: QtObject {
        // Rubik is what caelestia ships; the fallbacks keep quickgreet legible
        // on a machine that doesn't have it.
        readonly property string family: "Rubik, Inter, Cantarell, sans-serif"
        readonly property string mono: "CaskaydiaCove Nerd Font, JetBrains Mono, monospace"
        // Optional — only used for glyph icons. Absent font degrades to no icon
        // rather than breaking layout (see components/Icon.qml).
        readonly property string icon: "Material Symbols Rounded"
    }

    readonly property QtObject sizes: QtObject {
        readonly property int cardWidth: 460
        readonly property int avatar: 116
        readonly property int passwordWidth: 380
    }
}
