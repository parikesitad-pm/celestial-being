import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// System tab: CPU load and temperature, memory, Iris Xe load. The NVIDIA GPU is left out on
// purpose: reading it wakes the card.
Item {
    id: page
    property real memTotal: 0   // GiB
    FileView {
        path: "/proc/meminfo"
        blockLoading: true
        onLoaded: {
            const m = text().match(/MemTotal:\s+(\d+)/)
            if (m) page.memTotal = parseInt(m[1]) / 1048576
        }
    }
    readonly property real mem: parseFloat(Ui.mem) || 0

    RowLayout {
        anchors.centerIn: parent
        spacing: 18
        Gauge { value: Ui.cpu / 100; reading: Ui.cpu + "%"; label: "CPU" }
        Gauge { value: Ui.temp / 100; reading: Ui.temp + "°"; label: "CPU TEMP"; hot: 0.9 }
        Gauge {
            value: page.memTotal > 0 ? page.mem / page.memTotal : 0
            reading: page.mem.toFixed(1); label: "RAM GiB"
        }
        Gauge { visible: Ui.igpu >= 0; value: Ui.igpu / 100; reading: Ui.igpu + "%"; label: "IRIS XE" }
    }
}
