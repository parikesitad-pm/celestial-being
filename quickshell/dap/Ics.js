.pragma library

// Minimal iCalendar reader for a Google Calendar feed: VEVENT start, title, and the common
// RRULE shapes (DAILY/WEEKLY/MONTHLY/YEARLY with INTERVAL, COUNT, UNTIL, weekly BYDAY) and EXDATE.
// Times with a TZID are read as local time, which matches a calendar kept in the laptop's zone.

const DAY = 86400000
const WEEKDAYS = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 }

function parseDate(value) {
    const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/.exec(value.trim())
    if (!m) return null
    if (!m[4]) return { date: new Date(+m[1], +m[2] - 1, +m[3]), allDay: true }
    if (m[7]) return { date: new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6])), allDay: false }
    return { date: new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]), allDay: false }
}

function unescape(text) {
    return text.replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1")
}

function expand(ev, rule, exdates, from, to) {
    const p = {}
    for (const part of rule.split(";")) { const kv = part.split("="); p[kv[0]] = kv[1] }
    const interval = Math.max(1, parseInt(p.INTERVAL || "1"))
    const count = p.COUNT ? parseInt(p.COUNT) : Infinity
    const until = p.UNTIL ? parseDate(p.UNTIL).date.getTime() : Infinity
    const byDay = p.BYDAY ? p.BYDAY.split(",").map(d => WEEKDAYS[d.slice(-2)]) : null
    const start = ev.start
    const out = []
    let n = 0
    // Walk day by day for DAILY/WEEKLY (cheap over a ~70 day window), month by month otherwise.
    for (let i = 0; i < 2000 && n < count; i++) {
        let d
        if (p.FREQ === "DAILY") d = new Date(start.getTime() + i * interval * DAY)
        else if (p.FREQ === "WEEKLY") {
            d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i, start.getHours(), start.getMinutes())
            const weeks = Math.floor((d - start) / (7 * DAY))
            const days = byDay || [start.getDay()]
            if (weeks % interval !== 0 || !days.includes(d.getDay())) continue
        } else if (p.FREQ === "MONTHLY") d = new Date(start.getFullYear(), start.getMonth() + i * interval, start.getDate(), start.getHours(), start.getMinutes())
        else if (p.FREQ === "YEARLY") d = new Date(start.getFullYear() + i * interval, start.getMonth(), start.getDate(), start.getHours(), start.getMinutes())
        else break
        if (d.getTime() > until || d.getTime() > to) break
        n++
        if (d.getTime() < from || exdates.includes(d.getTime())) continue
        out.push({ start: d, allDay: ev.allDay, title: ev.title })
    }
    return out
}

function parse(text, nowMs) {
    const from = nowMs - 7 * DAY, to = nowMs + 62 * DAY
    // Long lines are folded onto continuation lines that start with a space.
    const lines = text.replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "").split(/\r?\n/)
    const out = []
    let ev = null
    for (const line of lines) {
        if (line === "BEGIN:VEVENT") { ev = { title: "", start: null, allDay: false, rule: "", ex: [] }; continue }
        if (line === "END:VEVENT") {
            if (ev && ev.start) {
                if (ev.rule) out.push(...expand(ev, ev.rule, ev.ex, from, to))
                else if (ev.start.getTime() >= from && ev.start.getTime() <= to) out.push({ start: ev.start, allDay: ev.allDay, title: ev.title })
            }
            ev = null
            continue
        }
        if (!ev) continue
        const colon = line.indexOf(":")
        if (colon < 0) continue
        const key = line.slice(0, colon).split(";")[0], value = line.slice(colon + 1)
        if (key === "SUMMARY") ev.title = unescape(value) || "(no title)"
        else if (key === "DTSTART") { const d = parseDate(value); if (d) { ev.start = d.date; ev.allDay = d.allDay } }
        else if (key === "RRULE") ev.rule = value
        else if (key === "EXDATE") for (const v of value.split(",")) { const d = parseDate(v); if (d) ev.ex.push(d.date.getTime()) }
    }
    return out.sort((x, y) => x.start - y.start)
}
