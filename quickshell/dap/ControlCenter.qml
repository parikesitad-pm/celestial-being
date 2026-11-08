import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// The right end of the bar: a status pill that springs open into the control center,
// with a sonar ping and a glitching systems check every time it opens.
PanelWindow {
    id: win
    anchors { top: true; right: true }
    margins { top: 6; right: 10 }
    implicitWidth: 380
    implicitHeight: openHeight + 12
    color: "transparent"
    exclusiveZone: -1
    WlrLayershell.namespace: "dap-cc"
    WlrLayershell.keyboardFocus: Ui.cc ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // Only the pill / panel takes input; the rest of this window lets clicks through.
    mask: Region { item: shape }

    HyprlandFocusGrab { windows: [win]; active: Ui.cc; onCleared: Ui.cleared("cc") }


    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var mic: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property real openHeight: col.implicitHeight + 32
    readonly property var pageTitles: ({ main: "ALL SYSTEMS NOMINAL", wifi: "WI-FI LINK", audio: "AUDIO ROUTING",
                                         display: "DISPLAY ARRAY", bluetooth: "BLUETOOTH LINK" })
    property bool wifiOn: true
    property string dispMode: "none"      // extend | mirror | pc | none
    property bool dispPortrait: false
    property string dispSide: "right"     // external monitor relative to the laptop
    property string armed: ""             // session tile waiting for a second click
    Timer { id: armTimer; interval: 3000; onTriggered: win.armed = "" }
    function armLater() { armTimer.restart() }
    property real brightness: 50
    function setBrightnessLater() { briDebounce.restart() }
    property string page: "main"          // main | wifi | audio | display | bluetooth
    onPageChanged: if (Ui.cc) { systems.target = "GN DRIVE // " + pageTitles[page]; systems.play() }
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
    function refocus() { card.forceActiveFocus() }
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
            if (code === 0) { win.wifiMsg = ""; win.pwdFor = ""; win.scanWifi(); Ui.cc = false }
            else win.wifiMsg = (connErr.text + connOut.text).trim().split("\n").pop() || "Could not connect"
        } }
    function refreshAudio() { pSinks.running = true; pSources.running = true; pDefSink.running = true; pDefSource.running = true }
    function openPage(n) {
        page = n
        if (n === "wifi") scanWifi()
        else if (n === "audio") refreshAudio()
        else if (n === "display") Hyprland.refreshMonitors()
    }
    function goMain() { page = "main"; pwdFor = ""; wifiMsg = ""; card.forceActiveFocus() }
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

    // ── refresh live state, and play the opening, whenever the panel opens ──
    Connections {
        target: Ui
        function onCcChanged() {
            win.armed = ""
            if (!Ui.cc) { win.goMain(); return }
            rWifi.running = true; rProf.running = true; rBri.running = true; rDisp.running = true
            systems.target = "GN DRIVE // " + win.pageTitles[win.page]
            systems.play()
            sonar.play()
            card.forceActiveFocus()
        }
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
        running: Ui.cc && !briDebounce.running
        onTriggered: {
            briNow.reload()
            const now = parseInt(briNow.text()), max = parseInt(briMax.text())
            if (max > 0 && !isNaN(now)) win.brightness = Math.round(now / max * 100)
        }
    }

    Binding { target: Ui; property: "ccPillWidth"; value: pill.implicitWidth + 28 }

    // ── one shape: status pill when closed, control center when open ──
    Rectangle {
        id: shape
        anchors.right: parent.right
        width: Ui.cc ? 372 : pill.implicitWidth + 28
        height: Ui.cc ? win.openHeight : 36
        radius: Ui.cc ? 28 : 18
        // Same under-damped spring as the island.
        Behavior on width { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.25 } }
        Behavior on height { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.25 } }
        Behavior on radius { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.25 } }
        color: Ui.cc || pillArea.containsMouse ? Theme.glassStrong : Theme.glass
        Behavior on color { ColorAnimation { duration: 150 } }
        border.width: 1; border.color: Theme.stroke
        clip: true

        MouseArea {
            id: pillArea
            anchors.fill: parent
            enabled: !Ui.cc
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.toggle("cc")
        }

        CcPill {
            id: pill
            anchors.right: parent.right; anchors.rightMargin: 14
            y: (36 - height) / 2
            sink: win.sink
            // Hidden at once when the panel grows; on close it waits for the shape to shrink first,
            // so it never overlaps the content mid-spring.
            visible: !Ui.cc
            opacity: visible ? 1 : 0
            Behavior on opacity {
                SequentialAnimation { PauseAnimation { duration: 180 } NumberAnimation { duration: 220 } }
            }
        }

        // Pings out from where the pill was.
        Sonar { id: sonar; x: shape.width - 40; y: 18; color: Theme.accent }

        // Fixed width, pinned to the top-right: the growing shape uncovers it like a curtain, and the
        // tiles never re-wrap mid-spring (which would resize the window and drop the focus grab).
        Item {
            id: card
            anchors.top: parent.top; anchors.right: parent.right
            anchors.margins: 16
            width: 340
            height: col.implicitHeight
            enabled: Ui.cc
            opacity: Ui.cc ? 1 : 0
            transform: Translate { y: Ui.cc ? 0 : -10; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: Ui.cc ? 260 : 90; easing.type: Easing.OutCubic } }
            focus: true
            Keys.onEscapePressed: {
                if (win.page === "main") Ui.cc = false
                else win.goMain()
            }
            Keys.onLeftPressed: if (win.page === "display") win.setSide("left")
            Keys.onRightPressed: if (win.page === "display") win.setSide("right")

            ColumnLayout {
                id: col
                anchors.left: parent.left; anchors.right: parent.right
                spacing: 8

                GlitchText {
                    id: systems
                    target: "GN DRIVE // ALL SYSTEMS NOMINAL"
                    font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
                    color: Theme.accent
                }

                // 12-column grid inside: 21 px cells + 8 px gaps fill the 340 px inner width.
                CcMainPage { cc: win; visible: win.page === "main"; Layout.fillWidth: true }
                CcWifiPage { cc: win; visible: win.page === "wifi"; Layout.fillWidth: true }
                CcAudioPage { cc: win; visible: win.page === "audio"; Layout.fillWidth: true }
                DisplayPage {
                    visible: win.page === "display"
                    side: win.dispSide
                    portrait: win.dispPortrait
                    onBack: win.goMain()
                    onSidePicked: s => win.setSide(s)
                }
                BluetoothPage {
                    visible: win.page === "bluetooth"
                    onBack: win.goMain()
                }
            }
        }
    }
}
