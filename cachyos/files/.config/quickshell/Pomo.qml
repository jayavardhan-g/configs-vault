pragma Singleton
// Pomodoro state + logic. Everything (settings, categories, session history and the
// running timer) persists to ~/.local/share/pomodoro/data.json, so a qs restart or a
// reboot resumes where it left off.
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: pomo

    // ── settings: cycle ──
    property int focusMin: 25
    property int shortMin: 5
    property int longMin: 15
    property int longEvery: 4
    property bool autoBreak: true
    property bool autoFocus: false
    property string mode: "timer"        // timer | stopwatch (counts up, no breaks)
    property bool strict: false          // no pause/skip during focus
    property int dailyGoalMin: 0         // 0 = off

    // ── settings: focus side effects ──
    property bool dnd: false             // Noctalia Do Not Disturb while focus runs
    property bool caffeine: false        // Noctalia caffeine (idle inhibitor) while focus runs
    property string sound: "complete"    // freedesktop sound at phase end, or "off"

    // ── settings: corner timer ──
    property real timerOpacity: 0.4      // background only; ring and digits stay solid
    property string monitorMode: "all"   // all | one
    property string monitorName: ""      // used when monitorMode is "one"
    property bool hideOnBreak: false

    // ── settings: notifications ({category}, {minutes} are filled in) ──
    property string focusDoneText: "Focus done — {category}"
    property string breakDoneText: "Break over — back to {category}"

    // Each: { name, color, focusMin?, shortMin? } (0/absent = use the defaults above)
    property var categories: [
        { name: "Study", color: "#89b4fa" },
        { name: "Coding", color: "#a6e3a1" },
        { name: "Work", color: "#fab387" },
        { name: "Reading", color: "#cba6f7" }
    ]
    property string category: "Study"

    // Each entry: { id, cat, end (ms epoch), min, done (false = stopped/skipped early) }
    property var sessions: []

    // ── live timer ──
    property string phase: "idle"        // idle | focus | short | long
    property bool running: false
    property real endsAt: 0              // timer mode: ms epoch, valid while running
    property int remaining: focusMin * 60
    property int phaseTotal: focusMin * 60
    property int cycleCount: 0           // focus sessions completed in this cycle
    property real runStart: 0            // stopwatch: ms epoch of the current run
    property int elapsedBase: 0          // stopwatch: seconds banked before the current run
    property int elapsed: 0              // stopwatch: seconds so far

    // Side effects this widget switched on (so it only switches off what it owns)
    property bool dndOwned: false
    property bool caffeineOwned: false

    // ── UI ──
    property bool panelOpen: false
    property string screenName: ""       // monitor the panel opens on

    readonly property bool active: phase !== "idle"
    readonly property bool isBreak: phase === "short" || phase === "long"
    readonly property bool stopwatch: mode === "stopwatch"
    readonly property bool locked: strict && phase === "focus"     // strict: no pause/skip
    readonly property real progress: stopwatch ? (elapsed % 3600) / 3600
                                   : phaseTotal > 0 ? 1 - remaining / phaseTotal : 0
    readonly property string phaseLabel: stopwatch && phase !== "idle" ? "Stopwatch"
                                       : ({ idle: "Ready", focus: "Focus", short: "Short break", long: "Long break" })[phase]
    readonly property color categoryColor: colorOf(category)
    readonly property color phaseColor: isBreak ? Theme.accent : categoryColor
    readonly property string timeText: stopwatch ? fmtClock(phase === "idle" ? 0 : elapsed) : fmtClock(remaining)

    readonly property int todayMin: totalMin(since(0))
    readonly property real goalProgress: dailyGoalMin > 0 ? Math.min(1, todayMin / dailyGoalMin) : 0

    readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/pomodoro"
    readonly property var sounds: ["off", "complete", "bell", "alarm-clock-elapsed"]
    property bool loaded: false

    // ── IPC: SUPER+C ──
    IpcHandler {
        target: "pomodoro"
        function toggle(): void { pomo.togglePanel() }
        function startPause(): void { pomo.running ? pomo.pause() : pomo.start() }
        function stop(): void { pomo.stop() }
    }

    // Hyprland.focusedMonitor stays null until the first focus event after qs starts,
    // so ask hyprctl directly, then open the panel on that monitor.
    Process {
        id: monitorProbe
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'"]
        stdout: StdioCollector {
            onStreamFinished: {
                pomo.screenName = this.text.trim();
                pomo.panelOpen = true;
            }
        }
    }

    function togglePanel() {
        if (panelOpen)
            panelOpen = false;
        else
            monitorProbe.running = true;
    }

    // ── timer ──
    Timer {
        interval: 250
        repeat: true
        running: pomo.running
        onTriggered: {
            if (pomo.stopwatch) {
                pomo.elapsed = pomo.elapsedBase + Math.floor((Date.now() - pomo.runStart) / 1000);
                return;
            }
            pomo.remaining = Math.max(0, Math.ceil((pomo.endsAt - Date.now()) / 1000));
            if (pomo.remaining === 0)
                pomo.finishPhase();
        }
    }

    function currentCat() {
        return categories.find(c => c.name === category) ?? {};
    }

    function minutesFor(p) {
        const c = currentCat();
        return p === "focus" ? (c.focusMin || focusMin)
             : p === "short" ? (c.shortMin || shortMin)
             : longMin;
    }

    // Idle display follows the current settings/category
    function resetIdle() {
        if (phase !== "idle")
            return;
        phaseTotal = minutesFor("focus") * 60;
        remaining = phaseTotal;
        elapsed = 0;
    }

    function beginPhase(p, autostart) {
        phase = p;
        phaseTotal = minutesFor(p) * 60;
        remaining = phaseTotal;
        running = autostart;
        if (running)
            endsAt = Date.now() + remaining * 1000;
        save();
    }

    function start() {
        if (stopwatch) {
            if (phase === "idle") {
                phase = "focus";
                elapsedBase = 0;
                elapsed = 0;
            }
            runStart = Date.now();
            running = true;
            save();
            return;
        }
        if (phase === "idle") {
            beginPhase("focus", true);
            return;
        }
        endsAt = Date.now() + remaining * 1000;
        running = true;
        save();
    }

    function pause() {
        if (locked)
            return;
        if (stopwatch && running) {
            elapsedBase = elapsedBase + Math.floor((Date.now() - runStart) / 1000);
            elapsed = elapsedBase;
        }
        running = false;
        save();
    }

    // Focus minutes actually spent in the current focus phase
    function elapsedFocusMin() {
        if (phase !== "focus")
            return 0;
        return stopwatch ? Math.floor(elapsed / 60) : Math.floor((phaseTotal - remaining) / 60);
    }

    function record(min, done) {
        if (min < 1)
            return;
        sessions = sessions.concat([{ id: newId(), cat: category, end: Date.now(), min: min, done: done }]);
    }

    function newId() {
        return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
    }

    function fill(text, minutes) {
        return text.replace(/\{category\}/g, category).replace(/\{minutes\}/g, minutes);
    }

    function finishPhase() {
        running = false;
        playSound();
        if (phase === "focus") {
            const min = Math.round(phaseTotal / 60);
            record(min, true);
            cycleCount++;
            const long = cycleCount % longEvery === 0;
            const next = long ? "long" : "short";
            notify(fill(focusDoneText, min), (long ? "Long" : "Short") + " break: " + minutesFor(next) + " min");
            beginPhase(next, autoBreak);
        } else {
            notify(fill(breakDoneText, minutesFor("focus")), "Next: " + minutesFor("focus") + " min of " + category);
            beginPhase("focus", autoFocus);
        }
    }

    function skip() {
        if (phase === "idle" || stopwatch || locked)
            return;
        if (phase === "focus") {
            record(elapsedFocusMin(), false);
            const long = (cycleCount + 1) % longEvery === 0;
            beginPhase(long ? "long" : "short", running && autoBreak);
        } else {
            beginPhase("focus", false);
        }
    }

    // Timer mode: ends the cycle (focus time so far is kept as a partial session).
    // Stopwatch mode: finishes the session and records it as completed.
    function stop() {
        if (stopwatch) {
            if (running)
                elapsed = elapsedBase + Math.floor((Date.now() - runStart) / 1000);
            if (phase === "focus") {
                if (Math.floor(elapsed / 60) >= 1)
                    playSound();
                record(Math.floor(elapsed / 60), true);
            }
            elapsedBase = 0;
            elapsed = 0;
        } else {
            record(elapsedFocusMin(), false);
        }
        running = false;
        phase = "idle";
        cycleCount = 0;
        resetIdle();
        save();
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", "-i", "alarm-symbolic", title, body]);
    }

    function playSound() {
        if (sound !== "off")
            Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/" + sound + ".oga"]);
    }

    // ── DND + caffeine while a focus session is running ──
    readonly property bool focusRunning: phase === "focus" && running
    onFocusRunningChanged: applyEffects()
    onDndChanged: applyEffects()
    onCaffeineChanged: applyEffects()

    Process {
        id: dndOn
        // Only take DND over if it's currently off, so a manual DND is left alone
        command: ["sh", "-c", "[ \"$(noctalia msg notification-dnd-status)\" = off ] && noctalia msg notification-dnd-set on >/dev/null && echo owned"]
        stdout: StdioCollector {
            onStreamFinished: { if (this.text.trim() === "owned") { pomo.dndOwned = true; pomo.save(); } }
        }
    }

    function applyEffects() {
        if (!loaded)
            return;
        const wantDnd = dnd && focusRunning;
        if (wantDnd && !dndOwned && !dndOn.running)
            dndOn.running = true;
        else if (!wantDnd && dndOwned) {
            Quickshell.execDetached(["noctalia", "msg", "notification-dnd-set", "off"]);
            dndOwned = false;
        }
        // Noctalia has no caffeine status command, so this can't tell a manual caffeine
        // apart: it is switched off whenever focus stops.
        const wantCaf = caffeine && focusRunning;
        if (wantCaf && !caffeineOwned) {
            Quickshell.execDetached(["noctalia", "msg", "caffeine-enable"]);
            caffeineOwned = true;
        } else if (!wantCaf && caffeineOwned) {
            Quickshell.execDetached(["noctalia", "msg", "caffeine-disable"]);
            caffeineOwned = false;
        }
        save();
    }

    function setSetting(key, value) {
        if (key === "mode" && phase !== "idle")
            return;                      // switch modes only between sessions
        pomo[key] = value;
        resetIdle();
        save();
    }

    // ── categories ──
    function colorOf(name) {
        const c = categories.find(c => c.name === name);
        return c ? c.color : Theme.accent;
    }

    function addCategory(name) {
        name = name.trim();
        if (!name || categories.some(c => c.name.toLowerCase() === name.toLowerCase()))
            return;
        const used = categories.map(c => c.color);
        const color = Theme.categoryColors.find(c => !used.includes(c))
                   ?? Theme.categoryColors[categories.length % Theme.categoryColors.length];
        categories = categories.concat([{ name: name, color: color }]);
        save();
    }

    // History keeps the name, so stats for a removed category still show (greyed).
    function removeCategory(name) {
        if (categories.length <= 1)
            return;
        categories = categories.filter(c => c.name !== name);
        if (category === name)
            category = categories[0].name;
        resetIdle();
        save();
    }

    // field: "focusMin" | "shortMin"; 0 = use the default
    function setCategoryMinutes(name, field, value) {
        categories = categories.map(c => {
            if (c.name !== name)
                return c;
            const copy = Object.assign({}, c);
            copy[field] = Math.max(0, value);
            return copy;
        });
        resetIdle();
        save();
    }

    function setCategory(name) {
        category = name;
        resetIdle();
        save();
    }

    // ── session history ──
    function updateSession(id, changes) {
        sessions = sessions.map(s => s.id === id ? Object.assign({}, s, changes) : s);
        save();
    }

    function deleteSession(id) {
        sessions = sessions.filter(s => s.id !== id);
        save();
    }

    function resetStats() {
        sessions = [];
        save();
    }

    FileView {
        id: exportFile
        printErrors: true
        onSaved: pomo.notify("Stats exported", path)
        onSaveFailed: err => pomo.notify("Export failed", path)
    }

    function exportCsv() {
        const esc = v => /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
        const rows = ["date,time,category,minutes,completed"].concat(
            sessions.slice().sort((a, b) => a.end - b.end).map(s => {
                const d = new Date(s.end);
                return [Qt.formatDate(d, "yyyy-MM-dd"), Qt.formatTime(d, "HH:mm"), esc(s.cat), s.min, s.done ? "yes" : "no"].join(",");
            }));
        exportFile.path = Quickshell.env("HOME") + "/Downloads/pomodoro-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmm") + ".csv";
        exportFile.setText(rows.join("\n") + "\n");
    }

    // ── stats ──
    function dayKey(ms) {
        const d = new Date(ms);
        return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
    }

    function dayStart(offsetDays) {
        const d = new Date();
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() - offsetDays);
        return d.getTime();
    }

    // Sessions since `days` days ago (0 = today only; -1 = all time)
    function since(days) {
        if (days < 0)
            return sessions;
        const from = dayStart(days);
        return sessions.filter(s => s.end >= from);
    }

    function totalMin(list) { return list.reduce((a, s) => a + s.min, 0); }
    function doneCount(list) { return list.filter(s => s.done).length; }

    // [{ name, color, min }] sorted by time, for the breakdown list
    function byCategory(list) {
        const m = {};
        for (const s of list)
            m[s.cat] = (m[s.cat] ?? 0) + s.min;
        return Object.keys(m).map(k => ({ name: k, color: categories.some(c => c.name === k) ? colorOf(k) : Theme.faint, min: m[k] }))
                     .sort((a, b) => b.min - a.min);
    }

    // Last 7 days, oldest first: [{ label, total, parts: [{color, min}] }]
    function week() {
        const out = [];
        for (let i = 6; i >= 0; i--) {
            const from = dayStart(i), to = dayStart(i - 1);
            const list = sessions.filter(s => s.end >= from && s.end < to);
            out.push({
                label: i === 0 ? "Today" : Qt.formatDate(new Date(from), "ddd"),
                total: totalMin(list),
                parts: byCategory(list)
            });
        }
        return out;
    }

    // Consecutive days with at least one completed focus session, counting back from
    // today (or from yesterday, if nothing is done yet today).
    function streak() {
        const days = new Set(sessions.filter(s => s.done).map(s => dayKey(s.end)));
        let n = 0;
        let i = days.has(dayKey(Date.now())) ? 0 : 1;
        while (days.has(dayKey(dayStart(i)))) { n++; i++; }
        return n;
    }

    function fmtClock(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60;
        const mm = (m < 10 ? "0" : "") + m, ss = (s < 10 ? "0" : "") + s;
        return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss;
    }

    function fmtDuration(min) {
        const h = Math.floor(min / 60), m = min % 60;
        return h > 0 ? h + "h" + (m > 0 ? " " + m + "m" : "") : m + "m";
    }

    // ── persistence ──
    Process {
        running: true
        command: ["mkdir", "-p", pomo.dataDir]
        onExited: store.path = pomo.dataDir + "/data.json"
    }

    FileView {
        id: store
        printErrors: false
        onLoaded: pomo.restore(text())
        onLoadFailed: { pomo.loaded = true; pomo.save(); }
    }

    readonly property var settingKeys: ["focusMin", "shortMin", "longMin", "longEvery", "autoBreak", "autoFocus",
        "mode", "strict", "dailyGoalMin", "dnd", "caffeine", "sound", "timerOpacity", "monitorMode",
        "monitorName", "hideOnBreak", "focusDoneText", "breakDoneText"]

    function restore(txt) {
        try {
            const d = JSON.parse(txt);
            const s = d.settings ?? {};
            for (const k of settingKeys)
                if (s[k] !== undefined)
                    pomo[k] = s[k];
            if (d.categories?.length)
                categories = d.categories;
            category = d.category ?? categories[0].name;
            // Older entries have no id; give them one so they can be edited
            sessions = (d.sessions ?? []).map((x, i) => x.id ? x : Object.assign({ id: "s" + i + "-" + x.end }, x));
            const t = d.timer ?? {};
            phase = t.phase ?? "idle";
            phaseTotal = t.phaseTotal ?? focusMin * 60;
            cycleCount = t.cycleCount ?? 0;
            remaining = t.remaining ?? phaseTotal;
            elapsedBase = t.elapsedBase ?? 0;
            elapsed = elapsedBase;
            dndOwned = t.dndOwned ?? false;
            caffeineOwned = t.caffeineOwned ?? false;
            if (t.running) {
                if (stopwatch) {
                    runStart = t.runStart ?? Date.now();
                    running = true;
                } else if (t.endsAt) {
                    endsAt = t.endsAt;
                    remaining = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000));
                    running = true;      // finishes on the next tick if it ran out meanwhile
                }
            }
        } catch (e) {
            console.warn("pomodoro: could not parse data.json:", e);
        }
        loaded = true;
        applyEffects();
    }

    function save() {
        if (!loaded)
            return;
        const settings = {};
        for (const k of settingKeys)
            settings[k] = pomo[k];
        store.setText(JSON.stringify({
            settings, categories, category, sessions,
            timer: { phase, running, endsAt, remaining, phaseTotal, cycleCount, runStart, elapsedBase, dndOwned, caffeineOwned }
        }, null, 1));
    }
}
