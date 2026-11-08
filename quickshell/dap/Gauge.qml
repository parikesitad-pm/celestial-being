import QtQuick
import QtQuick.Shapes

// Round gauge: a 270° track, a value arc that eases to new readings, the reading in the middle.
// Turns Trans-Am red past `hot`.
Item {
    id: g
    property real value: 0          // 0..1
    property string reading: ""
    property string label: ""
    property real hot: 0.85
    readonly property color tint: value >= hot ? Theme.transAmRed : Theme.accent
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

    implicitWidth: 120; implicitHeight: 120
    readonly property real r: Math.min(width, height) / 2 - 8

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.tile; strokeWidth: 8; capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g.r; radiusY: g.r; startAngle: 135; sweepAngle: 270 }
        }
        ShapePath {
            strokeColor: g.tint; strokeWidth: 8; capStyle: ShapePath.RoundCap; fillColor: "transparent"
            PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g.r; radiusY: g.r; startAngle: 135; sweepAngle: Math.max(0.5, 270 * Math.min(1, g.shown)) }
        }
    }
    Column {
        anchors.centerIn: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: g.reading
            font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Bold
            font.features: { "tnum": 1 }
            color: Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: g.label
            font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 1
            color: Theme.subtext
        }
    }
}
