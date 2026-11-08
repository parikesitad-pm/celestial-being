import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

// Control Center page: connect saved devices and pair new ones.
// PIN prompts come from the agent registered by blueman-applet.
ColumnLayout {
    id: page
    signal back()

    Layout.fillWidth: true; spacing: 8

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: !!adapter && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var saved: devices.filter(d => d.paired || d.bonded).sort((a, b) => b.connected - a.connected)
    // Devices with rotating addresses show up repeatedly, so each name is listed once.
    readonly property var nearby: {
        const seen = {}
        return devices.filter(d => {
            if (d.paired || d.bonded || d.deviceName === "" || seen[d.deviceName]) return false
            seen[d.deviceName] = true
            return true
        }).slice(0, 6)
    }

    // Discovery slows Wi-Fi on the shared radio, so it only runs while this page is open.
    readonly property bool scanning: visible && powered
    onScanningChanged: if (adapter) adapter.discovering = scanning

    // A freshly paired device moves between lists, so the follow-up connect is tracked here.
    property string pairingAddress: ""
    readonly property var pairingDevice: devices.find(d => d.address === pairingAddress) ?? null
    Connections {
        target: page.pairingDevice
        function onPairedChanged() {
            if (!page.pairingDevice.paired) return
            page.pairingDevice.trusted = true
            page.pairingDevice.connect()
            page.pairingAddress = ""
        }
    }

    function status(d) {
        if (d.pairing) return "Pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (!d.connected) return ""
        return d.batteryAvailable ? "Connected · " + Math.round(d.battery * 100) + "%" : "Connected"
    }
    function toggleSaved(d) {
        if (d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting) return
        if (d.connected) d.disconnect()
        else d.connect()
    }
    function pairNearby(d) {
        if (d.pairing) { pairingAddress = ""; d.cancelPair(); return }
        pairingAddress = d.address
        d.pair()
    }

    component Heading: Text {
        font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        color: Theme.subtext; renderType: Text.NativeRendering
    }
    component Note: Text {
        font.family: Theme.font; font.pixelSize: 12; color: Theme.subtext
        Layout.fillWidth: true; wrapMode: Text.WordWrap; renderType: Text.NativeRendering
    }

    PageHeader { title: "Bluetooth"; busy: page.scanning; onBack: page.back() }

    Note {
        visible: !page.powered
        text: page.adapter ? "Bluetooth is off. Turn it on from the main page." : "No Bluetooth adapter found."
    }

    Heading { visible: page.powered && page.saved.length > 0; text: "MY DEVICES" }
    Repeater {
        model: page.powered ? page.saved : []
        delegate: PickRow {
            required property var modelData
            title: modelData.name || modelData.address
            sub: page.status(modelData)
            current: modelData.connected
            onPicked: page.toggleSaved(modelData)
        }
    }

    Heading { visible: page.powered; text: "NEARBY"; Layout.topMargin: 6 }
    Note { visible: page.powered && page.nearby.length === 0; text: "Looking for devices…" }
    Repeater {
        model: page.powered ? page.nearby : []
        delegate: PickRow {
            required property var modelData
            title: modelData.name || modelData.address
            sub: page.status(modelData)
            onPicked: page.pairNearby(modelData)
        }
    }

    PickRow {
        title: "Advanced settings…"
        onPicked: { Ui.island = false; Ui.sh("blueman-manager") }
    }
}
