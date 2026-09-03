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

    // Drives both masking rectangles below so they can never drift apart.
    readonly property int shapeRadius: {
        switch (Config.appearance.avatarShape) {
        case "square":
            return 0;
        case "rounded":
            return Tokens.rounding.large;
        default:
            return Math.round(root.width / 2);
        }
    }

    // Squircle isn't radius-expressible, so it's a separate shape entirely
    // rather than a shapeRadius value — see components/Squircle.qml.
    readonly property bool squircle: Config.appearance.avatarShape === "squircle"

    Item {
        anchors.fill: parent
        visible: !root.hasImage

        StyledRect {
            anchors.fill: parent
            radius: root.shapeRadius
            color: Colours.c.primaryContainer ?? Colours.c.surfaceContainerHigh
            visible: !root.squircle
        }

        Squircle {
            anchors.fill: parent
            color: Colours.c.primaryContainer ?? Colours.c.surfaceContainerHigh
            visible: root.squircle
        }

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
            radius: root.shapeRadius
            color: "black"
            visible: !root.squircle
        }

        Squircle {
            anchors.fill: parent
            color: "black"
            visible: root.squircle
        }
    }
}
