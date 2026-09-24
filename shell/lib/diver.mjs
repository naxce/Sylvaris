const api = (function () {
  const DAY = 86400000;
  const REPEATS = ["none", "daily", "weekdays", "weekly", "monthly"];
  const ENERGY = ["low", "med", "high"];

  function uid() {
    if (typeof crypto !== "undefined" && crypto.randomUUID)
      return crypto.randomUUID();
    return (
      Date.now().toString(36) + Math.random().toString(36).slice(2, 10)
    );
  }

  function pad(n) {
    return String(n).padStart(2, "0");
  }

  function dayKey(d) {
    const x = d instanceof Date ? d : new Date(d);
    return x.getFullYear() + "-" + pad(x.getMonth() + 1) + "-" + pad(x.getDate());
  }

  function parseDay(key) {
    if (typeof key !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(key)) return null;
    const [y, m, d] = key.split("-").map(Number);
    return new Date(y, m - 1, d);
  }

  function isTime(v) {
    return typeof v === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(v);
  }

  function at(key, time) {
    const d = parseDay(key);
    if (!d) return null;
    const [h, m] = isTime(time) ? time.split(":").map(Number) : [9, 0];
    d.setHours(h, m, 0, 0);
    return d.getTime();
  }

  function cleanTask(t, today) {
    const task = Object.assign({}, t);
    if (!task.id) task.id = uid();
    task.text = typeof task.text === "string" ? task.text : "";
    task.done = task.done === true;
    if (task.schedule && typeof task.schedule === "object") {
      const s = task.schedule;
      const time = s.type === "range" ? s.from : s.at;
      if (isTime(time)) {
        task.time = time;
        if (s.type === "range" && isTime(s.to)) task.end = s.to;
        task.due = task.due || today;
        task.repeat = s.mode === "once" ? "none" : "daily";
        task.remind = [0];
      }
      delete task.schedule;
    }
    delete task._notifiedToday;
    if (task.due !== undefined && !parseDay(task.due)) delete task.due;
    if (task.time !== undefined && !isTime(task.time)) delete task.time;
    if (task.end !== undefined && !isTime(task.end)) delete task.end;
    if (task.repeat !== undefined && REPEATS.indexOf(task.repeat) < 0) delete task.repeat;
    if (task.energy !== undefined && ENERGY.indexOf(task.energy) < 0) delete task.energy;
    if (task.remind !== undefined)
      task.remind = Array.isArray(task.remind)
        ? task.remind.filter((m) => Number.isInteger(m) && m >= 0 && m <= 10080)
        : [];
    if (task.subtasks !== undefined)
      task.subtasks = Array.isArray(task.subtasks)
        ? task.subtasks
            .filter((s) => s && typeof s.text === "string")
            .map((s) => ({ id: s.id || uid(), text: s.text, done: s.done === true }))
        : [];
    return task;
  }

  function migrate(data, now) {
    const today = dayKey(now === undefined ? Date.now() : now);
    const list = Array.isArray(data) ? data : [];
    return list.map((item) => {
      const cat = item && item.groups
        ? item
        : { name: item && item.name, open: !item || item.open !== false, groups: [{ name: "general", open: true, subs: (item && item.subs) || [] }] };
      return Object.assign({}, cat, {
        id: cat.id || uid(),
        name: String(cat.name || ""),
        open: cat.open !== false,
        groups: (cat.groups || []).map((g) =>
          Object.assign({}, g, {
            id: g.id || uid(),
            name: String(g.name || ""),
            open: g.open !== false,
            subs: (g.subs || []).map((s) =>
              Object.assign({}, s, {
                id: s.id || uid(),
                name: String(s.name || ""),
                open: s.open !== false,
                dives: (s.dives || []).map((t) => cleanTask(t, today)),
              }),
            ),
          }),
        ),
      });
    });
  }

  function tasks(data) {
    const out = [];
    (data || []).forEach((c, ci) =>
      (c.groups || []).forEach((g, gi) =>
        (g.subs || []).forEach((s, si) =>
          (s.dives || []).forEach((t, ti) =>
            out.push({ task: t, ci, gi, si, ti, path: [c.name, g.name, s.name] }),
          ),
        ),
      ),
    );
    return out;
  }

  function find(data, id) {
    return tasks(data).find((x) => x.task.id === id) || null;
  }

  function step(key, repeat) {
    const d = parseDay(key);
    if (repeat === "daily") d.setDate(d.getDate() + 1);
    else if (repeat === "weekdays") {
      do d.setDate(d.getDate() + 1);
      while (d.getDay() === 0 || d.getDay() === 6);
    } else if (repeat === "weekly") d.setDate(d.getDate() + 7);
    else if (repeat === "monthly") {
      const day = d.getDate();
      d.setDate(1);
      d.setMonth(d.getMonth() + 1);
      d.setDate(Math.min(day, new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()));
    } else return null;
    return dayKey(d);
  }

  function occurrences(task, from, to) {
    if (!task || !task.due || task.done) return [];
    const repeat = task.repeat || "none";
    const out = [];
    let key = task.due;
    if (repeat === "weekdays") {
      const d = parseDay(key);
      if (d.getDay() === 0 || d.getDay() === 6) key = step(key, "weekdays");
    }
    for (let guard = 0; key && guard < 1000; guard++) {
      const t = at(key, task.time);
      if (t > to) break;
      if (t >= from) out.push(t);
      if (repeat === "none") break;
      key = step(key, repeat);
    }
    return out;
  }

  function reminders(data, from, to) {
    const out = [];
    for (const { task, path } of tasks(data)) {
      if (!task.time || task.done) continue;
      const offsets = Array.isArray(task.remind) && (task.remind.length > 0 || !task.alarm) ? task.remind : [0];
      const lead = Math.max(0, ...offsets) * 60000;
      for (const occ of occurrences(task, from, to + lead)) {
        for (const m of offsets) {
          const fire = occ - m * 60000;
          if (fire < from || fire > to) continue;
          out.push({
            rid: task.id + "@" + occ + "-" + m,
            id: task.id,
            at: fire,
            start: occ,
            before: m,
            alarm: task.alarm === true,
            title: plain(task.text),
            path: path.filter(Boolean).join(" · "),
          });
        }
      }
      if (task.snoozedUntil && task.snoozedUntil >= from && task.snoozedUntil <= to)
        out.push({
          rid: task.id + "@snooze-" + task.snoozedUntil,
          id: task.id,
          at: task.snoozedUntil,
          start: task.snoozedUntil,
          before: 0,
          alarm: task.alarm === true,
          title: plain(task.text),
          path: path.filter(Boolean).join(" · "),
        });
    }
    return out.sort((a, b) => a.at - b.at);
  }

  function agenda(data, day) {
    const start = parseDay(day).getTime();
    const end = start + DAY - 1;
    const items = [];
    for (const x of tasks(data)) {
      const t = x.task;
      if (t.done || !t.due) continue;
      const occ = occurrences(t, start, end);
      if (occ.length > 0) items.push(Object.assign({}, x, { start: occ[0], allDay: !t.time }));
    }
    return items.sort((a, b) => (a.allDay === b.allDay ? a.start - b.start : a.allDay ? 1 : -1));
  }

  function overdue(data, now) {
    const today = dayKey(now);
    return tasks(data).filter(
      (x) => !x.task.done && x.task.due && x.task.due < today && (x.task.repeat || "none") === "none",
    );
  }

  function busyDays(data, year, month) {
    const from = new Date(year, month, 1).getTime();
    const to = new Date(year, month + 1, 1).getTime() - 1;
    const days = {};
    for (const { task } of tasks(data))
      for (const occ of occurrences(task, from, to)) {
        const k = dayKey(occ);
        days[k] = (days[k] || 0) + 1;
      }
    return days;
  }

  function complete(task, done, now) {
    const t = Object.assign({}, task, { updatedAt: now });
    delete t.snoozedUntil;
    if (done && t.due && t.repeat && t.repeat !== "none") {
      let next = step(t.due, t.repeat);
      const today = dayKey(now);
      while (next && next <= today) next = step(next, t.repeat);
      t.due = next;
      t.done = false;
      t.streak = (t.streak || 0) + 1;
      t.subtasks = (t.subtasks || []).map((s) => Object.assign({}, s, { done: false }));
      return t;
    }
    t.done = done;
    if (done) t.doneAt = now;
    else delete t.doneAt;
    return t;
  }

  function plain(text) {
    return String(text || "")
      .split("\n")[0]
      .replace(/[*_`~#>\[\]]/g, "")
      .replace(/\((https?:[^)]*)\)/g, "")
      .trim()
      .slice(0, 120);
  }


  const WEEKDAYS = {
    sunday: 0, sun: 0, niedziela: 0, niedz: 0,
    monday: 1, mon: 1, poniedzialek: 1, poniedziałek: 1, pon: 1,
    tuesday: 2, tue: 2, wtorek: 2, wt: 2,
    wednesday: 3, wed: 3, sroda: 3, środa: 3, sr: 3, śr: 3,
    thursday: 4, thu: 4, czwartek: 4, czw: 4,
    friday: 5, fri: 5, piatek: 5, piątek: 5, pt: 5,
    saturday: 6, sat: 6, sobota: 6, sob: 6,
  };

  function quick(input, now) {
    const base = new Date(now === undefined ? Date.now() : now);
    let text = String(input || "").trim();
    let due = null;
    let time = null;
    let exact = null;
    const take = (re, fn) => {
      const m = text.match(re);
      if (!m) return;
      fn(m);
      text = (text.slice(0, m.index) + " " + text.slice(m.index + m[0].length)).replace(/\s+/g, " ").trim();
    };
    take(/(?:^|\s)(?:in|za)\s+(\d{1,3})\s*(min|mins|minutes|minut|m|h|hours|hour|godz|godzin|godziny)(?=\s|$)/i, (m) => {
      const n = Number(m[1]);
      exact = base.getTime() + (/^(h|hour|hours|godz|godzin|godziny)$/i.test(m[2]) ? n * 60 : n) * 60000;
    });
    take(/(?:^|\s)(today|dzis|dziś|tonight|wieczorem)(?=\s|$)/i, (m) => {
      due = dayKey(base);
      if (/tonight|wieczorem/i.test(m[1]) && !time) time = "20:00";
    });
    take(/(?:^|\s)(tomorrow|tmr|jutro)(?=\s|$)/i, () => {
      const d = new Date(base);
      d.setDate(d.getDate() + 1);
      due = dayKey(d);
    });
    const names = Object.keys(WEEKDAYS).sort((a, b) => b.length - a.length).join("|");
    take(new RegExp("(?:^|\\s)(?:on\\s+|w\\s+|we\\s+)?(" + names + ")(?=\\s|$)", "i"), (m) => {
      const wd = WEEKDAYS[m[1].toLowerCase()];
      const d = new Date(base);
      const diff = (wd - d.getDay() + 7) % 7 || 7;
      d.setDate(d.getDate() + diff);
      due = dayKey(d);
    });
    take(/(?:^|\s)(?:at\s+|o\s+|@)?([01]?\d|2[0-3])(?::|\.)([0-5]\d)(?=\s|$)/i, (m) => {
      time = String(m[1]).padStart(2, "0") + ":" + m[2];
    });
    take(/(?:^|\s)(?:at|o|@)\s*([01]?\d|2[0-3])(?=\s|$)/i, (m) => {
      time = String(m[1]).padStart(2, "0") + ":00";
    });
    if (exact !== null) {
      const d = new Date(exact);
      return { text: text, due: dayKey(d), time: String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0") };
    }
    if (time && !due) {
      const t = at(dayKey(base), time);
      const d = new Date(base);
      if (t <= base.getTime()) d.setDate(d.getDate() + 1);
      due = dayKey(d);
    }
    return { text: text, due: due, time: time };
  }

  function same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
  }

  function strip(node, childKey) {
    const o = Object.assign({}, node);
    delete o[childKey];
    return o;
  }

  function mergeList(base, local, remote, childKey, grandKeys) {
    const b = new Map((base || []).map((x) => [x.id, x]));
    const l = new Map((local || []).map((x) => [x.id, x]));
    const r = new Map((remote || []).map((x) => [x.id, x]));
    const order = [];
    for (const x of remote || []) order.push(x.id);
    for (const x of local || []) if (!r.has(x.id)) order.push(x.id);
    const out = [];
    for (const id of order) {
      const bn = b.get(id);
      const ln = l.get(id);
      const rn = r.get(id);
      if (!ln && bn && rn) {
        const changedRemote = !same(bn, rn);
        if (!changedRemote) continue;
      }
      if (!rn && bn) {
        if (!ln || same(bn, ln)) continue;
      }
      if (!rn && !bn && ln) {
        out.push(ln);
        continue;
      }
      const lv = ln || bn || rn;
      const rv = rn || bn || ln;
      const bv = bn || null;
      let merged;
      if (childKey) {
        const localChanged = bv && !same(strip(bv, childKey), strip(lv, childKey));
        merged = Object.assign({}, localChanged ? strip(lv, childKey) : strip(rv, childKey));
        merged[childKey] = mergeList(
          bv ? bv[childKey] : [],
          lv[childKey],
          rv[childKey],
          grandKeys[0],
          grandKeys.slice(1),
        );
      } else {
        const localChanged = bv ? !same(bv, lv) : true;
        const remoteChanged = bv ? !same(bv, rv) : true;
        if (localChanged && remoteChanged) merged = (lv.updatedAt || 0) >= (rv.updatedAt || 0) ? lv : rv;
        else merged = localChanged ? lv : rv;
      }
      out.push(merged);
    }
    return out;
  }

  function merge3(base, local, remote) {
    return mergeList(base || [], local || [], remote || [], "groups", ["subs", "dives", null]);
  }

  return { DAY, REPEATS, ENERGY, uid, dayKey, parseDay, isTime, at, migrate, tasks, find, step, occurrences, reminders, agenda, overdue, busyDays, complete, plain, merge3, quick };
})();

export const { DAY, REPEATS, ENERGY, uid, dayKey, parseDay, isTime, at, migrate, tasks, find, step, occurrences, reminders, agenda, overdue, busyDays, complete, plain, merge3, quick } = api;
