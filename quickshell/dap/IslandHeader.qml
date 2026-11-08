import QtQuick
import QtQuick.Layouts

// Open island header: mark + callsign, caution tape, and under it the pill's clock and stats,
// which slide in when the island opens so the time stays in view on every tab.
ColumnLayout {
    id: head
    property bool running: false
    spacing: 6

    function play(text, slideIn) {
        callsign.target = text
        callsign.play()
        if (slideIn) slide.restart()
    }

    RowLayout {
        spacing: 8
        DapLogo { size: 18 }
        DecodeText {
            id: callsign
            target: "CELESTIAL BEING // PILOT dap_"
            font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
            font.letterSpacing: 1
            color: Theme.gold
        }
    }

    HazardStripe {
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        running: head.running
    }

    IslandPill {
        id: status
        Layout.fillWidth: true
        spread: true
        transform: Translate { id: statusShift }
    }
    ParallelAnimation {
        id: slide
        NumberAnimation { target: statusShift; property: "x"; from: -48; to: 0; duration: 480; easing.type: Easing.OutExpo }
        NumberAnimation { target: status; property: "opacity"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
    }
}
