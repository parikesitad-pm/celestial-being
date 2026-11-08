import QtQuick
import QtQuick.Shapes

// Hollow rounded rectangle filled with a rotating conical gradient: the shell's version of
// Hyprland's active_border + borderangle loop. Only the gradient angle changes per frame.
Shape {
    id: ring
    property real thickness: 1.5
    property real radius: height / 2
    property real angle: 0
    // The gradient only travels while true; otherwise the ring stays lit but still (no redraws).
    property bool spinning: true
    // When set, every stop takes this color (NT-D's solid psycho-frame red).
    property color solid: "transparent"
    // Four stops replacing Theme.border, e.g. the closed island's GN green radar.
    property var colors: null
    function stop(i) { return solid.a > 0 ? solid : (colors ? colors[i] : Theme.border[i]) }

    preferredRendererType: Shape.CurveRenderer

    FrameAnimation {
        running: ring.visible && ring.spinning
        onTriggered: ring.angle = (ring.angle + 360 * frameTime * 1000 / Theme.borderLoopMs) % 360
    }

    ShapePath {
        strokeColor: "transparent"
        strokeWidth: 0
        fillRule: ShapePath.OddEvenFill
        fillGradient: ConicalGradient {
            centerX: ring.width / 2
            centerY: ring.height / 2
            angle: ring.angle
            GradientStop { position: 0; color: ring.stop(0) }
            GradientStop { position: 0.25; color: ring.stop(1) }
            GradientStop { position: 0.5; color: ring.stop(2) }
            GradientStop { position: 0.75; color: ring.stop(3) }
            GradientStop { position: 1; color: ring.stop(0) }
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
