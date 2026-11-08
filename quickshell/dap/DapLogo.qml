import QtQuick
import QtQuick.Shapes

// dap_'s mark (hexagon, prompt chevron, cursor) as vector paths on a 1024 grid,
// so it stays sharp at any size without an image file.
Item {
    id: logo
    property real size: 20
    property color line: "#c0c9f4"
    property color cursor: "#b8214a"
    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 1024; height: 1024
        scale: logo.size / 1024
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: logo.line
            strokeWidth: 52
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 512; startY: 214
            PathLine { x: 771; y: 363 }
            PathLine { x: 771; y: 661 }
            PathLine { x: 512; y: 810 }
            PathLine { x: 253; y: 661 }
            PathLine { x: 253; y: 363 }
            PathLine { x: 512; y: 214 }
        }
        ShapePath {
            strokeColor: logo.line
            strokeWidth: 52
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 427; startY: 427
            PathLine { x: 526; y: 512 }
            PathLine { x: 427; y: 597 }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: logo.cursor
            PathRectangle { x: 564; y: 576; width: 88; height: 40; radius: 10 }
        }
    }
}
