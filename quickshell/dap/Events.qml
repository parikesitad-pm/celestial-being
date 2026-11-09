import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// System events shown as island toasts with a sound: wired and Wi-Fi links (from stats.sh, no extra
// process), USB drives (udisksctl monitor), charger, and volume.
Item {
    id: ev

    // The first values after start are the current state, not events.
    property bool armed: false
    Timer { interval: 4000; running: true; onTriggered: ev.armed = true }

    // ───────── network: Ui.lan / Ui.ssid come from stats.sh every 2 s ─────────
    property string lastLan: ""
    property string lastSsid: ""
    property bool plugged: true
    Connections {
        target: Ui
        function onLanChanged() {
            const was = ev.lastLan
            ev.lastLan = Ui.lan
            if (!ev.armed) return
            if (Ui.lan === "up") Ui.alert({ kind: "net", glyph: 0xF0318, app: "VEDA", sound: "link-up",
                summary: "GN LINK ESTABLISHED", body: "Wired connection online" })
            else if (was === "up") Ui.alert({ kind: "net", glyph: 0xF0319, app: "VEDA", sound: "link-down",
                summary: "GN LINK SEVERED", body: "Cable disconnected" })
        }
        function onSsidChanged() {
            const was = ev.lastSsid
            ev.lastSsid = Ui.ssid
            if (!ev.armed) return
            if (Ui.ssid !== "") Ui.alert({ kind: "net", glyph: 0xF0928, app: "VEDA", sound: "link-up",
                summary: "VEDA LINK ONLINE", body: Ui.ssid })
            else if (was !== "") Ui.alert({ kind: "net", glyph: 0xF092D, app: "VEDA", sound: "link-down",
                summary: "VEDA LINK LOST", body: "Switching to standalone · " + was })
        }
        // Plugged = any status but Discharging, so a battery that reaches Full is not "charger released".
        function onBatStatusChanged() {
            const plugged = Ui.batStatus !== "Discharging"
            const was = ev.plugged
            ev.plugged = plugged
            if (!ev.armed || Ui.battery < 0 || Ui.batStatus === "" || was === plugged) return
            if (plugged) Ui.alert({ kind: "power", glyph: 0xF0084, app: "GN DRIVE", sound: "charge",
                summary: "GN DRIVE CHARGING", body: "Condenser at " + Ui.battery + "%" })
            else Ui.alert({ kind: "power", glyph: 0xF0079, app: "GN DRIVE", sound: "discharge",
                summary: "ON CONDENSER POWER", body: "Charger released · " + Ui.battery + "%" })
        }
    }

    // ───────── USB drives: whole disks only (sdX), announced once each ─────────
    property var docked: ({})
    Process {
        running: true
        command: ["udisksctl", "monitor"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/: (Added|Removed) \/org\/freedesktop\/UDisks2\/block_devices\/(sd[a-z]+)$/)
                if (!m) return
                if (m[1] === "Added") { probe.dev = m[2]; probe.running = true }
                else if (ev.docked[m[2]]) {
                    const name = ev.docked[m[2]]
                    const d = Object.assign({}, ev.docked); delete d[m[2]]; ev.docked = d
                    Ui.alert({ kind: "drive", glyph: 0xF02CA, app: "HANGAR", sound: "release",
                        summary: "CONTAINER RELEASED", body: name })
                }
            }
        }
    }
    Process {
        id: probe
        property string dev: ""
        command: ["lsblk", "-dno", "TRAN,SIZE,MODEL", "/dev/" + dev]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/)
                if (p[0] !== "usb") return
                const name = (p.slice(2).join(" ") || "Drive") + " · " + p[1]
                const d = Object.assign({}, ev.docked); d[probe.dev] = name; ev.docked = d
                Ui.alert({ kind: "drive", glyph: 0xF02CA, app: "HANGAR", sound: "dock",
                    summary: "CONTAINER DOCKED", body: name })
            }
        }
    }

    function sortie(ok, cmd, took) {
        Ui.alert({ kind: "sortie", glyph: 0xF018D, app: "VEDA LOG", sound: ok ? "link-up" : "link-down",
            summary: ok ? "SORTIE COMPLETE" : "SORTIE FAILED", body: cmd + " · " + took })
    }

    // Preview from IPC: qs -c dap ipc call shell demo <kind>
    function demo(kind) {
        const a = {
            "lan-up":    { kind: "net", glyph: 0xF0318, app: "VEDA", sound: "link-up", summary: "GN LINK ESTABLISHED", body: "Wired connection online" },
            "lan-down":  { kind: "net", glyph: 0xF0319, app: "VEDA", sound: "link-down", summary: "GN LINK SEVERED", body: "Cable disconnected" },
            "wifi-up":   { kind: "net", glyph: 0xF0928, app: "VEDA", sound: "link-up", summary: "VEDA LINK ONLINE", body: Ui.ssid || "Network" },
            "wifi-down": { kind: "net", glyph: 0xF092D, app: "VEDA", sound: "link-down", summary: "VEDA LINK LOST", body: "Switching to standalone" },
            "dock":      { kind: "drive", glyph: 0xF02CA, app: "HANGAR", sound: "dock", summary: "CONTAINER DOCKED", body: "Flash Drive · 64G" },
            "release":   { kind: "drive", glyph: 0xF02CA, app: "HANGAR", sound: "release", summary: "CONTAINER RELEASED", body: "Flash Drive · 64G" },
            "charge":    { kind: "power", glyph: 0xF0084, app: "GN DRIVE", sound: "charge", summary: "GN DRIVE CHARGING", body: "Condenser at " + Ui.battery + "%" },
            "discharge": { kind: "power", glyph: 0xF0079, app: "GN DRIVE", sound: "discharge", summary: "ON CONDENSER POWER", body: "Charger released · " + Ui.battery + "%" }
        }[kind]
        if (a) Ui.alert(a)
    }

    // ───────── volume: replaces the old bottom pill ─────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property double lastTick: 0
    function volume() {
        if (!armed || !audio) return
        const now = Date.now()
        const tick = now - lastTick > 150
        if (tick) lastTick = now
        const pct = Math.round(audio.volume * 100)
        Ui.alert({ kind: "volume", glyph: audio.muted ? 0xF075F : 0xF057E, sound: tick ? "tick" : "",
            summary: audio.muted ? "SILENT RUNNING" : "GN OUTPUT", level: audio.muted ? 0 : Math.min(1, audio.volume),
            body: audio.muted ? "" : pct + "%" })
    }
    Connections {
        target: ev.audio
        ignoreUnknownSignals: true
        function onVolumeChanged() { ev.volume() }
        function onMutedChanged() { ev.volume() }
    }
}
