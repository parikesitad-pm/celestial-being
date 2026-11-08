import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

// Collapsed control center: volume, Bluetooth, network, battery. Each icon pops when its value
// changes; Wi-Fi and LAN also send out a ring when they connect.
RowLayout {
    id: row
    property var sink: null
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : true
    readonly property bool bt: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    spacing: 12

    // Fixed character count (monospace font), so a changing digit count doesn't resize the pill.
    function pad(v, n) { return String(v).padStart(n, " ") }

    component Label: Text {
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
    }

    RowLayout {
        spacing: 5
        CcPop {
            text: Theme.g(row.muted ? 0xF075F : 0xF057E); color: Theme.purple
            watch: row.muted ? -1 : Math.round(row.vol * 100)
        }
        Label { visible: !row.muted; text: row.pad(Math.round(row.vol * 100), 3) + "%" }
    }
    CcPop {
        text: Theme.g(row.bt ? 0xF00AF : 0xF00B2); color: row.bt ? Theme.blue : Theme.subtext
        watch: row.bt
    }
    CcPop {
        visible: Ui.lan !== ""
        text: Theme.g(Ui.lan === "up" ? 0xF0318 : 0xF0319)
        color: Ui.lan === "up" ? Theme.text : Theme.subtext
        watch: Ui.lan
        ping: Ui.lan === "up"
    }
    CcPop {
        text: Theme.g(Ui.ssid !== "" ? 0xF0928 : 0xF092D)
        color: Ui.ssid !== "" ? Theme.text : Theme.subtext
        watch: Ui.ssid
        ping: Ui.ssid !== ""
    }
    RowLayout {
        spacing: 5
        visible: Ui.battery >= 0
        CcPop {
            text: Theme.g(Ui.charging ? 0xF0084 : 0xF0079)
            color: Ui.battery < 20 && !Ui.charging ? Theme.red : Theme.accent
            watch: Ui.charging
        }
        Label { text: row.pad(Ui.battery, 3) + "%" }
    }
}
