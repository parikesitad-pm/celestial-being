pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Pinned and running apps for the side bar: one entry per app, with its open windows.
Singleton {
    id: apps
    // lastIpcObject stays empty on a new window until refreshToplevels() runs; appId is set right away.
    function clsOf(t) { return (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject.class) || "" }
    function matches(entry, cls) {
        if (!entry || !cls) return false
        const c = cls.toLowerCase()
        return entry.id.toLowerCase() === c || (entry.startupClass || "").toLowerCase() === c || entry.id.toLowerCase().endsWith("." + c) || entry.id.toLowerCase().includes(c)
    }
    // DesktopEntries scans asynchronously and byId() is not reactive, so without this
    // the pinned apps stay missing after login until a window opens or closes.
    property int entriesRevision: 0
    Timer { id: entriesSettled; interval: 50; onTriggered: apps.entriesRevision++ }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { entriesSettled.restart() }
    }

    readonly property var items: {
        void entriesRevision
        const tls = Hyprland.toplevels.values
        const out = [{ key: "launcher", entry: null, wins: [], cls: "appgrid", pinned: true, isLauncher: true }], used = {}
        for (const id of Ui.pinned) {
            const e = DesktopEntries.byId(id)
            if (!e) continue
            const w = tls.filter(t => matches(e, clsOf(t)))
            w.forEach(t => used[t.address] = true)
            out.push({ key: id, entry: e, wins: w, cls: e.id, pinned: true })
        }
        const extra = {}
        for (const t of tls) {
            const c = clsOf(t)
            if (used[t.address] || c === "") continue
            if (!extra[c]) { extra[c] = { key: "c:" + c, entry: DesktopEntries.heuristicLookup(c), wins: [], cls: c, pinned: false }; out.push(extra[c]) }
            extra[c].wins.push(t)
        }
        return out
    }
    readonly property var byKey: {
        const m = {}
        for (const it of items) m[it.key] = it
        return m
    }
    readonly property int pinnedCount: items.filter(it => it.pinned).length

    function activate(it) {
        if (it.wins.length > 0) {
            const t = it.wins[0]
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })")
        } else if (it.entry) it.entry.execute()
    }
}
