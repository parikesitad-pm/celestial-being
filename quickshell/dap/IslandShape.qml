import QtQuick
import QtQuick.Shapes

// The island's body, attached to the top screen edge: flat top, concave fillets where it meets the
// edge, rounded bottom corners. A glow ring runs along the sides and bottom (not the screen edge).
// x/y of this item are the body's top-left; the fillets reach `fillet` px past each side.
Shape {
    id: s
    property real w: 100
    property real h: 36
    property real radius: 18
    property real fillet: 14
    property real thickness: 1.5
    property color fill: Theme.glass
    // Ring, as in GlowRing: four gradient stops that travel while `spinning`, or one `solid` color.
    property bool spinning: false
    property color solid: "transparent"
    property var colors: null
    property real angle: 0
    function stop(i) { return solid.a > 0 ? solid : (colors ? colors[i] : Theme.border[i]) }

    width: w; height: h
    preferredRendererType: Shape.CurveRenderer

    readonly property real r: Math.min(radius, h / 2, w / 2)
    readonly property real f: fillet
    readonly property real t: thickness
    readonly property string outer:
        `M ${-f} 0 L ${w + f} 0 A ${f} ${f} 0 0 0 ${w} ${f} L ${w} ${h - r} A ${r} ${r} 0 0 1 ${w - r} ${h}`
        + ` L ${r} ${h} A ${r} ${r} 0 0 1 0 ${h - r} L 0 ${f} A ${f} ${f} 0 0 0 ${-f} 0 Z`
    readonly property real ri: Math.max(0, r - t)
    readonly property string inner:
        `M ${-f} ${-t} L ${w + f} ${-t} A ${f + t} ${f + t} 0 0 0 ${w - t} ${f} L ${w - t} ${h - r}`
        + ` A ${ri} ${ri} 0 0 1 ${w - r} ${h - t} L ${r} ${h - t} A ${ri} ${ri} 0 0 1 ${t} ${h - r}`
        + ` L ${t} ${f} A ${f + t} ${f + t} 0 0 0 ${-f} ${-t} Z`

    FrameAnimation {
        running: s.visible && s.spinning
        onTriggered: s.angle = (s.angle + 360 * frameTime * 1000 / Theme.borderLoopMs) % 360
    }

    ShapePath {
        strokeColor: "transparent"
        fillColor: s.fill
        PathSvg { path: s.outer }
    }
    ShapePath {
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        fillGradient: ConicalGradient {
            centerX: s.w / 2
            centerY: s.h / 2
            angle: s.angle
            GradientStop { position: 0; color: s.stop(0) }
            GradientStop { position: 0.25; color: s.stop(1) }
            GradientStop { position: 0.5; color: s.stop(2) }
            GradientStop { position: 0.75; color: s.stop(3) }
            GradientStop { position: 1; color: s.stop(0) }
        }
        PathSvg { path: s.outer + " " + s.inner }
    }
}
