pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Ics.js" as Ics

// Everything on a clock: focus timer, todos, alarms, and Google Calendar events.
Singleton {
    id: a
    readonly property string state: Quickshell.env("HOME") + "/.local/state/"

    // ───────── focus timer (runs from the island, counts down in the pill) ─────────
    property int focusMinutes: 25
    property double focusEnd: 0   // epoch ms; 0 = stopped
    readonly property int focusLeft: focusEnd > 0 ? Math.max(0, Math.ceil((focusEnd - Ui.now.getTime()) / 1000)) : 0
    function focusStart() { focusEnd = Date.now() + focusMinutes * 60000 }
    function focusStop() { focusEnd = 0 }

    // ───────── todo list ─────────
    property var todos: []   // [{ text, done }]
    function saveTodos() { todoFile.setText(JSON.stringify(todos) + "\n") }
    function addTodo(t) {
        t = t.trim()
        if (!t) return
        todos = todos.concat([{ text: t, done: false }])
        saveTodos()
    }
    function toggleTodo(i) {
        todos = todos.map((t, j) => j === i ? { text: t.text, done: !t.done } : t)
        saveTodos()
    }
    function removeTodo(i) { todos = todos.filter((_, j) => j !== i); saveTodos() }
    FileView {
        id: todoFile
        path: a.state + "dap-shell-todo.json"
        onLoaded: { try { const t = JSON.parse(text()); if (Array.isArray(t)) a.todos = t } catch (e) { console.warn("todo list unreadable:", e) } }
    }

    // ───────── alarms ─────────
    property var alarms: []   // [{ at: epoch ms, label }], soonest first
    function saveAlarms() { alarmFile.setText(JSON.stringify(alarms) + "\n") }
    // Returns false for an unreadable time or one already in the past.
    function addAlarm(day, hhmm, label) {
        const m = /^(\d{1,2})[:.](\d{2})$/.exec(hhmm.trim())
        if (!m || +m[1] > 23 || +m[2] > 59) return false
        const at = new Date(day.getFullYear(), day.getMonth(), day.getDate(), +m[1], +m[2]).getTime()
        if (at <= Date.now()) return false
        alarms = alarms.concat([{ at: at, label: label.trim() || "Alarm" }]).sort((x, y) => x.at - y.at)
        saveAlarms()
        return true
    }
    function removeAlarm(at) { alarms = alarms.filter(x => x.at !== at); saveAlarms() }
    FileView {
        id: alarmFile
        path: a.state + "dap-shell-alarms.json"
        onLoaded: { try { const t = JSON.parse(text()); if (Array.isArray(t)) a.alarms = t } catch (e) { console.warn("alarms unreadable:", e) } }
    }

    // Focus end and alarms fire on the shell's one-second clock.
    Connections {
        target: Ui
        function onNowChanged() {
            const now = Ui.now.getTime()
            if (a.focusEnd > 0 && now >= a.focusEnd) {
                a.focusEnd = 0
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Focus", "Focus done", "Time for a break."])
                a.ring()
            }
            const due = a.alarms.filter(x => x.at <= now)
            if (due.length === 0) return
            a.alarms = a.alarms.filter(x => x.at > now)
            a.saveAlarms()
            for (const x of due)
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Alarm", x.label, Qt.formatDateTime(new Date(x.at), "HH:mm")])
            a.ring()
        }
    }
    function ring() { Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]) }

    // ───────── Google Calendar (read-only, via the calendar's secret iCal address) ─────────
    // The address is a credential: it lives only in this file, which dap fills in himself.
    readonly property string icsUrlFile: Quickshell.env("HOME") + "/.config/dap-shell/gcal-ics-url"
    property string icsUrl: ""
    property var events: []        // [{ start: Date, allDay, title }] from a week ago to two months ahead
    property string calStatus: ""  // "" = not linked, "ok", "error"
    FileView {
        path: a.icsUrlFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { a.icsUrl = text().trim(); a.fetch() }
    }
    function fetch() { if (icsUrl !== "") fetcher.running = true }
    Timer { interval: 15 * 60 * 1000; repeat: true; running: a.icsUrl !== ""; onTriggered: a.fetch() }
    Process {
        id: fetcher
        command: ["curl", "-fsSL", "--max-time", "20", a.icsUrl]
        stdout: StdioCollector { onStreamFinished: if (text.includes("BEGIN:VCALENDAR")) a.events = Ics.parse(text, Date.now()) }
        onExited: code => a.calStatus = code === 0 ? "ok" : "error"
    }

    // Calendar events and alarms on one day, earliest first; all-day events lead.
    function itemsOn(day) {
        const same = d => d.getFullYear() === day.getFullYear() && d.getMonth() === day.getMonth() && d.getDate() === day.getDate()
        const ev = events.filter(e => same(e.start)).map(e => ({ kind: "event", time: e.start.getTime(), allDay: e.allDay, title: e.title }))
        const al = alarms.filter(x => same(new Date(x.at))).map(x => ({ kind: "alarm", time: x.at, allDay: false, title: x.label, at: x.at }))
        return ev.concat(al).sort((x, y) => (y.allDay - x.allDay) || (x.time - y.time))
    }
    function busy(day) { return itemsOn(day).length > 0 }

    // ───────── month grid ─────────
    // Monday-first 6×7 grid, shared by the calendar popup and the island.
    function monthGrid(v, today) {
        const y = v.getFullYear(), m = v.getMonth()
        const start = (new Date(y, m, 1).getDay() + 6) % 7
        const dim = new Date(y, m + 1, 0).getDate()
        const prev = new Date(y, m, 0).getDate()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = i - start + 1
            if (d < 1) out.push({ d: prev + d, cur: false, today: false, date: new Date(y, m - 1, prev + d) })
            else if (d > dim) out.push({ d: d - dim, cur: false, today: false, date: new Date(y, m + 1, d - dim) })
            else out.push({ d: d, cur: true, date: new Date(y, m, d),
                            today: y === today.getFullYear() && m === today.getMonth() && d === today.getDate() })
        }
        return out
    }
}
