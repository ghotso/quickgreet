import QtQuick
import qs.config
import qs.services

// Text with quickgreet's font and colour defaults applied, plus a smooth
// colour transition so a live palette reload doesn't snap.
Text {
    id: root

    color: Colours.c.onSurface
    font.family: Tokens.font.family
    font.pixelSize: 15
    renderType: Text.NativeRendering
    textFormat: Text.PlainText

    Behavior on color {
        ColorAnimation {
            duration: Tokens.durations.slowEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.easing.expressiveEffects
        }
    }
}
