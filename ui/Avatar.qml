import QtQuick
import QtQuick.Effects
import qs.components
import qs.config
import qs.services

// Circular avatar: ~/.face if there is one, otherwise the user's initial.
//
// Most machines have no ~/.face, so the fallback is the common path, not the
// exception — it uses initials rather than an icon glyph so it always renders
// as something deliberate, with no icon-font dependency and nothing to go
// missing in a bare greeter's fontconfig.
Item {
    id: root

    property string user: ""
    property string displayName: ""

    implicitWidth: Tokens.px(Tokens.sizes.avatar)
    implicitHeight: Tokens.px(Tokens.sizes.avatar)

    // Empty until Config has confirmed the file exists — see Config.avatarExists.
    readonly property string path: Config.avatarExists ? Config.avatarPath : ""
    readonly property bool hasImage: image.status === Image.Ready

    readonly property string initial: {
        const src = (displayName || user || "").trim();
        return src.length ? src[0].toUpperCase() : "?";
    }

    StyledRect {
        anchors.fill: parent
        radius: width / 2
        color: Colours.c.primaryContainer ?? Colours.c.surfaceContainerHigh
        visible: !root.hasImage

        StyledText {
            anchors.centerIn: parent
            text: root.initial
            color: Colours.c.onPrimaryContainer ?? Colours.c.onSurface
            font.pixelSize: Math.round(root.height * 0.42)
            font.weight: Font.Medium
        }
    }

    Image {
        id: image

        anchors.fill: parent
        source: root.path ? `file://${root.path}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize.width: Tokens.px(Tokens.sizes.avatar) * 2
        sourceSize.height: Tokens.px(Tokens.sizes.avatar) * 2
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        visible: root.hasImage
        maskEnabled: true
        maskSource: mask
    }

    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black"
        }
    }
}
