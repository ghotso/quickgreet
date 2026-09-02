import QtQuick
import qs.config

// NumberAnimation preset carrying quickgreet's motion tokens, so individual
// components don't each hand-roll durations and bezier curves.
NumberAnimation {
    id: root

    enum Type {
        Standard,
        StandardAccel,
        StandardDecel,
        Spatial,
        Effects
    }

    property int type: Anim.Type.Spatial

    duration: {
        switch (type) {
        case Anim.Type.Effects:
            return Tokens.durations.defaultEffects;
        case Anim.Type.Spatial:
            return Tokens.durations.defaultSpatial;
        default:
            return Tokens.durations.normal;
        }
    }

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (type) {
        case Anim.Type.StandardAccel:
            return Tokens.easing.standardAccel;
        case Anim.Type.StandardDecel:
            return Tokens.easing.standardDecel;
        case Anim.Type.Spatial:
            return Tokens.easing.expressiveSpatial;
        case Anim.Type.Effects:
            return Tokens.easing.expressiveEffects;
        default:
            return Tokens.easing.standard;
        }
    }
}
