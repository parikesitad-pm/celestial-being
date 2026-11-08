pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

Singleton {
    id: s

    // ───────── media ─────────
    // Spotify's desktop app also publishes a Chromium player for its embedded web view
    // ("Spotify - Web Player" when paused); hide Chromium players while Spotify is open.
    readonly property var players: {
        const ps = Mpris.players.values
        const spotify = ps.some(p => p.dbusName.includes("spotify"))
        return ps.filter(p => !(spotify && p.dbusName.includes("chromium")))
    }
    property var picked: null   // the player that started playing last, or the one clicked in the notch
    readonly property var player: picked && players.includes(picked)
        ? picked : (players.find(p => p.isPlaying) || players[0] || null)
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() { if (modelData.isPlaying) s.picked = modelData }
        }
    }
    // ───────── island ─────────
    property bool island: false

    // ───────── notifications: this shell is the notification server (swaync is retired) ─────────
    property bool dnd: false   // hides toasts; notifications still land in the Notif tab
    property int islandTab: 0
    property var notifs: []    // newest first: { ref, id, app, icon, summary, body, time, critical, actions }
    property var toast: null   // shown by the collapsed island for a few seconds
    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/")) return "file://" + icon
        if (icon.includes("://")) return icon
        return Quickshell.iconPath(icon, true)
    }
    function dropNotif(id) {
        notifs = notifs.filter(n => n.id !== id)
        if (toast && toast.id === id) toast = null
    }
    function dismissNotif(n) {
        try { if (n.ref) n.ref.dismiss() } catch (e) {}
        dropNotif(n.id)
    }
    function clearNotifs() { notifs.slice().forEach(n => dismissNotif(n)) }
    function invokeAction(n, action) {
        try { action.invoke() } catch (e) { console.warn("notification action failed:", e) }
        dropNotif(n.id)
    }
    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true
            const item = {
                ref: n, id: n.id, app: n.appName,
                icon: n.image || n.appIcon || n.desktopEntry,
                summary: n.summary, body: n.body, time: new Date(),
                critical: n.urgency === NotificationUrgency.Critical,
                actions: n.actions
            }
            // The sender closing it (a call that stopped ringing, a message read elsewhere) removes it here too.
            n.closed.connect(() => s.dropNotif(item.id))
            s.notifs = [item].concat(s.notifs.filter(o => o.id !== item.id)).slice(0, 50)
            if (!s.island && (!s.dnd || item.critical)) {
                s.toast = item
                toastTimer.interval = item.critical ? 6000 : 3500
                toastTimer.restart()
            }
        }
    }
    Timer { id: toastTimer; interval: 3500; onTriggered: s.toast = null }
    function mmss(sec) {
        const t = Math.max(0, Math.floor(sec || 0))
        return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0")
    }

    // Display names only: workspace IDs stay numeric for keybinds and hyprland.lua.
    // 1-4 are the fixed desktops; the rest name desktops added from the Overview.
    readonly property int baseDesks: 4
    readonly property var deskNames: ["Exia", "Dynames", "Kyrios", "Virtue", "Freedom", "Zaku",
                                      "Unicorn", "00 Raiser", "RX-78-2", "Strike", "Wing", "Barbatos"]
    function deskName(id) { return deskNames[id - 1] || "Desktop " + id }
    function addDesk(id, focus) { sh("hyprctl eval 'dap_add_desktop(" + id + ", " + focus + ")'") }
    function removeDesk(id) { sh("hyprctl eval 'dap_remove_desktop(" + id + ")'") }

    // One calm edge color: anime blue normally, red in Trans-Am. Desktops share it.
    function deskColor(id) { return transAm ? Theme.transAmRed : Theme.anime }

    // Power profile lives here so the whole shell can react to it; "performance" is Trans-Am.
    property string profile: "balanced"
    readonly property bool transAm: profile === "performance"
    Process {
        id: profileRead
        running: true
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: s.profile = text.trim() }
    }
    // Profile changes from anywhere (powerprofilesctl, power-profiles-daemon) arrive as D-Bus signals.
    Process {
        running: true
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.DBus.Properties',path='/net/hadess/PowerProfiles'"]
        stdout: SplitParser { onRead: line => { if (line.includes("ActiveProfile")) profileRead.running = true } }
    }

    // Window edges take the focused desktop's color; Trans-Am only changes the color.
    readonly property int activeDesk: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
        ? Hyprland.focusedMonitor.activeWorkspace.id : 1
    function applyBorder() {
        const c = String(transAm ? Theme.transAmRed : Theme.anime)
        const stops = [c, Qt.darker(c, 2.4).toString()]
        const cols = stops.map(x => '"rgba(' + String(x).slice(1) + 'ff)"').join(", ")
        sh("hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {" + cols + "}, angle = 45 } } } }); "
           + "hl.animation({ leaf = \"borderangle\", enabled = true, speed = 40"
           + ", bezier = \"linear\", style = \"loop\" })'")
    }
    onActiveDeskChanged: borderSync.restart()
    onTransAmChanged: borderSync.restart()
    Timer { id: borderSync; interval: 40; onTriggered: s.applyBorder() }
    // A config reload puts the static gradient from hyprland.lua back; reapply on top of it.
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "configreloaded") borderSync.restart() }
    }
    Component.onCompleted: borderSync.restart()

    // Top bar placement. Screens are matched by description (it includes the serial) because connector names change between docks.
    property bool barMainOnly: false
    property string barMainKey: ""
    function screenKey(screen) {
        const monitor = Hyprland.monitorFor(screen)
        return monitor && monitor.description ? monitor.description : screen.name
    }
    function screenLabel(screen) { return screen.name.startsWith("eDP") ? "Laptop" : (screen.model || screen.name) }
    // If the main display is unplugged the bar returns everywhere, so it can never disappear.
    readonly property var barScreens: {
        const all = Quickshell.screens
        if (!barMainOnly) return all
        const main = all.filter(x => screenKey(x) === barMainKey)
        return main.length > 0 ? main : all
    }
    function setBarMainOnly(on) {
        barMainOnly = on
        if (on && !Quickshell.screens.some(x => screenKey(x) === barMainKey)) {
            const all = Quickshell.screens
            barMainKey = screenKey(all.find(x => !x.name.startsWith("eDP")) ?? all[0])
        }
        saveBar()
    }
    function setBarMain(screen) { barMainKey = screenKey(screen); saveBar() }
    function saveBar() { barFile.setText(JSON.stringify({ mainOnly: barMainOnly, main: barMainKey }) + "\n") }
    FileView {
        id: barFile
        path: Quickshell.env("HOME") + "/.local/state/dap-shell-bar.json"
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                s.barMainOnly = saved.mainOnly === true
                s.barMainKey = saved.main || ""
            } catch (e) {
                console.warn("bar placement unreadable, showing on all displays:", e)
            }
        }
    }

    property bool launcher: false
    property bool calendar: false
    property bool cc: false
    property bool overview: false
    property bool shot: false
    property bool preview: false
    property string previewKind: ""
    property string previewPath: ""
    property int previewSize: 0
    property string clearedName: ""
    property double clearedAt: 0

    // live system stats (fed by scripts/stats.sh)
    property int cpu: 0
    property string mem: "0.0"
    property int temp: 0
    property int battery: -1
    property bool charging: false

    // GN particles low: one critical alarm at 15% and one at 5% while discharging.
    // Re-arms once the charger is in or the battery is back above 20%.
    property int gnWarned: 100
    onBatteryChanged: gnCheck()
    onChargingChanged: gnCheck()
    function gnCheck() {
        if (battery < 0) return
        if (charging || battery > 20) { gnWarned = 100; return }
        const level = battery <= 5 ? 5 : battery <= 15 ? 15 : 100
        if (level >= gnWarned) return
        gnWarned = level
        sh("notify-send -u critical -a 'GN Drive' 'GN particles low · " + battery + "%' '"
           + (level === 5 ? "Plug in now, shutdown is close." : "Connect the charger.") + "'")
    }
    property int igpu: -1         // Intel clock-based estimate, -1 = none
    property int gpu: -1          // -1 = no readable NVIDIA GPU
    property string lan: ""       // "up", "down", or "" = no wired interface
    property string ssid: ""
    property int signal: 0

    // dock pins: desktop entry ids, saved on every change
    property var pinned: ["zen", "kitty", "org.kde.dolphin", "com.obsproject.Studio", "Zoom"]
    function isPinned(id) { return pinned.includes(id) }
    function togglePin(id) {
        pinned = isPinned(id) ? pinned.filter(p => p !== id) : pinned.concat([id])
        pinsFile.setText(JSON.stringify(pinned) + "\n")
    }
    FileView {
        id: pinsFile
        path: Quickshell.env("HOME") + "/.local/state/dap-dock-pins.json"
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (Array.isArray(saved)) s.pinned = saved
            } catch (e) {
                console.warn("dock pins unreadable, using defaults:", e)
            }
        }
    }

    property var now: new Date()
    SystemClock { id: clk; precision: SystemClock.Seconds; onDateChanged: s.now = clk.date }

    function closeAll() { sheet = ""; select = ""; island = false; launcher = false; calendar = false; cc = false; overview = false; shot = false; preview = false }
    // Island tabs (see Island.tabs): 0 Haro, 1 Mission, 2 Sortie, 3 Orders, 4 Comms, 5 Veda, 6 Hangar.
    // Sheets shown in the island instead of the tabs: "bridge" (control center), "launch" (session),
    // "sense" (gn-sense).
    property string sheet: ""
    // Region picker (RegionSelect.qml): "shot" or "record" while it is open.
    property string select: ""
    // gn-sense's card, embedded as the "sense" sheet; empty when gn-sense is not installed.
    readonly property string senseCardPath: Quickshell.env("HOME") + "/.config/quickshell/gn-sense/SenseCard.qml"
    property string senseCard: ""
    Process {
        running: true
        command: ["test", "-f", s.senseCardPath]
        onExited: code => { if (code === 0) s.senseCard = "file://" + s.senseCardPath }
    }
    function openSheet(name) {
        const was = island && sheet === name
        closeAll()
        if (was) return
        sheet = name
        island = true
    }
    function openIsland(tab) {
        if (island && islandTab === tab) { island = false; return }
        closeAll()
        islandTab = tab
        island = true
    }
    function toggle(name) {
        if (name === "cc") { openSheet("bridge"); return }
        if (clearedName === name && Date.now() - clearedAt < 250) return   // click-outside just closed it
        const was = s[name]
        closeAll()
        s[name] = !was
    }
    function cleared(name) { clearedName = name; clearedAt = Date.now(); s[name] = false }
    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function workspace(i) { sh("hyprctl dispatch 'hl.dsp.focus({ workspace = " + i + " })'") }

    Process {
        command: [Theme.scripts + "stats.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const p = data.split("|")
                if (p.length < 10) return
                s.cpu = parseInt(p[0]) || 0
                s.mem = p[1]
                s.temp = parseInt(p[2]) || 0
                s.battery = p[3] === "" ? -1 : parseInt(p[3])
                s.charging = p[4] === "Charging"
                const ig = parseInt(p[5])
                s.igpu = isNaN(ig) ? -1 : ig
                const g = parseInt(p[6])
                s.gpu = isNaN(g) ? -1 : g
                s.lan = p[7]
                s.ssid = p[8]
                s.signal = parseInt(p[9]) || 0
            }
        }
    }
    Process {
        command: ["cat", Quickshell.env("HOME") + "/.local/state/dap-theme"]
        running: true
        stdout: StdioCollector { onStreamFinished: Theme.dark = text.trim() !== "light" }
    }
}
