import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
// Control center, shown as the island's Bridge sheet: toggles, sliders, power profiles, displays,
// GN Sense, and the Wi-Fi / audio / display / Bluetooth pages.
// GN Sense, and the Wi-Fi / audio / display / Bluetooth pages. Shown as the island's Bridge sheet.
Item {
    id: win
    property bool shown: false
    implicitHeight: col.implicitHeight
    focus: shown
    Keys.onEscapePressed: event => {
        if (page !== "main") { goMain(); event.accepted = true }
        else event.accepted = false
    }
    Keys.onLeftPressed: if (page === "display") setSide("left")
    Keys.onRightPressed: if (page === "display") setSide("right")

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var mic: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    property bool wifiOn: true
    property string dispMode: "none"      // extend | mirror | pc | none
    property bool dispPortrait: false
    property string dispSide: "right"     // external monitor relative to the laptop
    property real brightness: 50
    function setBrightnessLater() { briDebounce.restart() }
    property string page: "main"          // main | wifi | audio | display | bluetooth
    property var nets: []
    property var sinks: []
    property var sources: []
    property string defSink: ""
    property string defSource: ""
    property var saved: []
    property string pwdFor: ""
    property string wifiMsg: ""
    property bool wifiBusy: false
    readonly property bool scanning: pScan.running
    readonly property string connectingTo: pConn.ssid
    function refocus() { win.forceActiveFocus() }
    function scanWifi() { pSaved.running = true; pScan.running = true }
    function connectWifi(ssid, pw) {
        wifiBusy = true; wifiMsg = ""
        pConn.ssid = ssid; pConn.pw = pw
        pConn.command = pw === "" ? ["nmcli", "dev", "wifi", "connect", ssid] : ["nmcli", "--ask", "dev", "wifi", "connect", ssid]
        pConn.running = true
    }
    Process { id: pSaved; command: ["nmcli", "-t", "-f", "NAME", "con", "show"]
        stdout: StdioCollector { onStreamFinished: win.saved = text.split("\n").filter(x => x !== "") } }
    Process { id: pConn
        property string ssid: ""
        property string pw: ""
        stdinEnabled: true
        onStarted: if (pw !== "") { write(pw + "\n") }
        stdout: StdioCollector { id: connOut }
        stderr: StdioCollector { id: connErr }
        onExited: code => {
            win.wifiBusy = false
            pw = ""
            if (code === 0) { win.wifiMsg = ""; win.pwdFor = ""; win.scanWifi(); Ui.island = false }
            else win.wifiMsg = (connErr.text + connOut.text).trim().split("\n").pop() || "Could not connect"
        } }
    function refreshAudio() { pSinks.running = true; pSources.running = true; pDefSink.running = true; pDefSource.running = true }
    function openPage(n) {
        page = n
        if (n === "wifi") scanWifi()
        else if (n === "audio") refreshAudio()
        else if (n === "display") Hyprland.refreshMonitors()
    }
    function goMain() { page = "main"; pwdFor = ""; wifiMsg = ""; win.forceActiveFocus() }
    Process { id: pScan; command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector { onStreamFinished: {
            const seen = {}, out = []
            for (const line of text.split("\n")) {
                const p = line.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"))
                if (p.length < 4 || !p[1] || seen[p[1]]) continue
                seen[p[1]] = true
                out.push({ ssid: p[1], signal: parseInt(p[2]) || 0, secure: p[3] !== "", active: p[0] === "*" })
            }
            // Replacing the model rebuilds the rows, which would wipe a password being typed.
            if (win.pwdFor === "") win.nets = out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal)).slice(0, 12)
        } } }
    Process { id: pSinks; command: ["pactl", "-f", "json", "list", "sinks"]
        stdout: StdioCollector { onStreamFinished: { try { win.sinks = JSON.parse(text).map(x => ({ name: x.name, desc: x.description })) } catch (e) {} } } }
    Process { id: pSources; command: ["pactl", "-f", "json", "list", "sources"]
        stdout: StdioCollector { onStreamFinished: { try { win.sources = JSON.parse(text).filter(x => !x.name.endsWith(".monitor")).map(x => ({ name: x.name, desc: x.description })) } catch (e) {} } } }
    Process { id: pDefSink;   command: ["pactl", "get-default-sink"];   stdout: StdioCollector { onStreamFinished: win.defSink = text.trim() } }
    Process { id: pDefSource; command: ["pactl", "get-default-source"]; stdout: StdioCollector { onStreamFinished: win.defSource = text.trim() } }
    Timer { id: afterSet; interval: 400; onTriggered: win.refreshAudio() }

    // Refresh live state whenever the Control tab is shown.
    onShownChanged: {
        if (!shown) { goMain(); return }
        rWifi.running = true; rProf.running = true; rBri.running = true; rDisp.running = true
    }
    Process { id: rDisp; command: [Theme.scripts + "display.sh", "status"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(" "); win.dispMode = p[0] || "none"; win.dispPortrait = p[1] === "1"; win.dispSide = p[2] || "right" } } }
    function setDisplay(m) { dispMode = m; Ui.sh(Theme.scripts + "display.sh " + m) }
    function setSide(s) { dispSide = s; Ui.sh(Theme.scripts + "display.sh " + s); sideCheck.restart() }
    // Reads the real position back, so the diagram corrects itself if the move failed.
    Timer { id: sideCheck; interval: 600; onTriggered: { rDisp.running = true; Hyprland.refreshMonitors() } }
    Process { id: rWifi; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: win.wifiOn = text.trim() === "enabled" } }
    Process { id: rProf; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: Ui.profile = text.trim() } }
    Process { id: rBri;  command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(","); if (p.length > 3) win.brightness = parseInt(p[3]) } } }
    Timer { id: briDebounce; interval: 60; onTriggered: Ui.sh("brightnessctl -q set " + Math.round(win.brightness) + "%") }
    FileView { id: briNow; path: "/sys/class/backlight/intel_backlight/brightness"; blockLoading: true }
    FileView { id: briMax; path: "/sys/class/backlight/intel_backlight/max_brightness"; blockLoading: true }
    Timer {
        interval: 250; repeat: true
        running: win.shown && !briDebounce.running
        onTriggered: {
            briNow.reload()
            const now = parseInt(briNow.text()), max = parseInt(briMax.text())
            if (max > 0 && !isNaN(now)) win.brightness = Math.round(now / max * 100)
        }
    }


    ColumnLayout {
        id: col
        anchors.left: parent.left; anchors.right: parent.right
        spacing: 8
        CcMainPage { cc: win; visible: win.page === "main"; Layout.fillWidth: true }
        CcWifiPage { cc: win; visible: win.page === "wifi"; Layout.fillWidth: true }
        CcAudioPage { cc: win; visible: win.page === "audio"; Layout.fillWidth: true }
        DisplayPage {
            visible: win.page === "display"
            Layout.fillWidth: true
            side: win.dispSide
            portrait: win.dispPortrait
            onBack: win.goMain()
            onSidePicked: s => win.setSide(s)
        }
        BluetoothPage {
            visible: win.page === "bluetooth"
            Layout.fillWidth: true
            onBack: win.goMain()
        }
    }
}
