import QtQuick
import QtQuick.Shapes

// A hollow rounded rectangle filled with a rotating conical gradient: Hyprland's
// "borderangle" loop. Only the gradient angle changes per frame, so the path is never rebuilt.
Shape {
    id: ring

    property real thickness: 2
    property real radius: height / 2
    property color colorA
    property color colorB
    property color colorC: colorA
    property real loopSeconds: 4
    property real angle: 0

    preferredRendererType: Shape.CurveRenderer

    FrameAnimation {
        running: ring.visible
        onTriggered: ring.angle = (ring.angle + 360 * frameTime / ring.loopSeconds) % 360
    }

    ShapePath {
        strokeColor: "transparent"
        strokeWidth: 0
        fillRule: ShapePath.OddEvenFill
        fillGradient: ConicalGradient {
            centerX: ring.width / 2
            centerY: ring.height / 2
            angle: ring.angle
            GradientStop { position: 0; color: ring.colorA }
            GradientStop { position: 0.34; color: ring.colorB }
            GradientStop { position: 0.67; color: ring.colorC }
            GradientStop { position: 1; color: ring.colorA }
        }
        PathRectangle {
            width: ring.width
            height: ring.height
            radius: ring.radius
        }
        PathRectangle {
            x: ring.thickness
            y: ring.thickness
            width: ring.width - 2 * ring.thickness
            height: ring.height - 2 * ring.thickness
            radius: Math.max(0, ring.radius - ring.thickness)
        }
    }
}
