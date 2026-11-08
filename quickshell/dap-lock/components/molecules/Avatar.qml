import QtQuick
import QtQuick.Shapes
import "../atoms"

Item {
    id: avatar

    property url source
    readonly property real photoSize: 120
    readonly property real border: 3

    width: photoSize + 2 * border
    height: width

    // Clipped by the path, so the photo stays round on any GPU without a mask shader pass.
    Shape {
        x: avatar.border
        y: avatar.border
        width: avatar.photoSize
        height: avatar.photoSize
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillItem: photo
            PathRectangle {
                width: avatar.photoSize
                height: avatar.photoSize
                radius: avatar.photoSize / 2
            }
        }
    }

    Image {
        id: photo
        width: avatar.photoSize
        height: avatar.photoSize
        source: avatar.source
        sourceSize: Qt.size(avatar.photoSize * 2, avatar.photoSize * 2)
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: false
        // Without a layer, the fill maps the 240 px texture at 1:1 and shows a 2x zoomed crop.
        layer.enabled: true
    }

    GradientRing {
        anchors.fill: parent
        thickness: avatar.border
        colorA: Tokens.green
        colorB: Tokens.blue
        loopSeconds: Tokens.borderLoop * 2
    }
}
