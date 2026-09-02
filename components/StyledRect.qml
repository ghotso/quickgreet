import QtQuick
import qs.config

// Rectangle that transitions its colour rather than snapping, so palette
// reloads and state changes (focus, error) read as motion.
Rectangle {
    id: root

    Behavior on color {
        ColorAnimation {
            duration: Tokens.durations.slowEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.easing.expressiveEffects
        }
    }
}
