const api = (function () {
  const DAY = 86400000;
  const REPEATS = ["none", "daily", "weekdays", "weekly", "monthly"];
  const ENERGY = ["low", "med", "high"];
  const UNITS = ["day", "week", "month", "year"];
  const LEGACY = {
    daily: { every: 1, unit: "day" },
    weekdays: { every: 1, unit: "week", days: [1, 2, 3, 4, 5] },
    weekly: { every: 1, unit: "week" },
    monthly: { every: 1, unit: "month" },
  };

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
    if (task.rule !== undefined) {
      const rule = validRule(task.rule);
      if (rule) {
        task.rule = rule;
        if (legacy(rule) === "none") delete task.repeat;
        else task.repeat = legacy(rule);
      } else delete task.rule;
    }
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

  function validRule(rule) {
    if (!rule || typeof rule !== "object" || UNITS.indexOf(rule.unit) < 0) return null;
    const out = { every: Number.isInteger(rule.every) && rule.every >= 1 && rule.every <= 999 ? rule.every : 1, unit: rule.unit };
    if (rule.unit === "week" && Array.isArray(rule.days)) {
      const days = rule.days.filter((d, i, a) => Number.isInteger(d) && d >= 0 && d <= 6 && a.indexOf(d) === i).sort((a, b) => a - b);
      if (days.length > 0) out.days = days;
    }
    if (parseDay(rule.until)) out.until = rule.until;
    return out;
  }

  function ruleOf(task) {
    if (!task) return null;
    return validRule(task.rule) || (LEGACY[task.repeat] ? Object.assign({}, LEGACY[task.repeat]) : null);
  }

  function legacy(rule) {
    if (!rule || rule.every !== 1) return "none";
    if (rule.unit === "day") return "daily";
    if (rule.unit === "month") return "monthly";
    if (rule.unit !== "week") return "none";
    if (!rule.days) return "weekly";
    return rule.days.join() === "1,2,3,4,5" ? "weekdays" : "none";
  }

  function monday(d) {
    return (d.getDay() + 6) % 7;
  }

  function addMonths(d, n) {
    const day = d.getDate();
    d.setDate(1);
    d.setMonth(d.getMonth() + n);
    d.setDate(Math.min(day, new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()));
  }

  function step(key, rule) {
    const d = parseDay(key);
    if (!d || !rule) return null;
    if (rule.unit === "day") d.setDate(d.getDate() + rule.every);
    else if (rule.unit === "week" && rule.days) {
      const order = rule.days.map((x) => (x + 6) % 7).sort((a, b) => a - b);
      const later = order.find((x) => x > monday(d));
      if (later !== undefined) d.setDate(d.getDate() + later - monday(d));
      else d.setDate(d.getDate() - monday(d) + 7 * rule.every + order[0]);
    } else if (rule.unit === "week") d.setDate(d.getDate() + 7 * rule.every);
    else if (rule.unit === "month") addMonths(d, rule.every);
    else if (rule.unit === "year") addMonths(d, 12 * rule.every);
    else return null;
    const next = dayKey(d);
    return rule.until && next > rule.until ? null : next;
  }

  function first(key, rule) {
    if (!rule || !rule.days) return key;
    const d = parseDay(key);
    while (rule.days.indexOf(d.getDay()) < 0) d.setDate(d.getDate() + 1);
    return dayKey(d);
  }

  function untilAfter(due, rule, n) {
    const r = validRule(rule);
    if (!r || !parseDay(due) || !(n >= 1)) return null;
    let key = first(due, r);
    for (let i = 1; i < n && key; i++) key = step(key, Object.assign({}, r, { until: undefined }));
    return key;
  }

  function splitText(text) {
    const lines = String(text || "").split("\n");
    return { title: lines[0], notes: lines.slice(1).join("\n") };
  }

  function joinText(title, notes) {
    const n = String(notes || "").trim();
    return String(title || "").trim() + (n ? "\n" + n : "");
  }

  function occurrences(task, from, to) {
    if (!task || !task.due || task.done) return [];
    const rule = ruleOf(task);
    const out = [];
    let key = first(task.due, rule);
    if (rule && rule.until && key > rule.until) return [];
    for (let guard = 0; key && guard < 1000; guard++) {
      const t = at(key, task.time);
      if (t > to) break;
      if (t >= from) out.push(t);
      if (!rule) break;
      key = step(key, rule);
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
      (x) => !x.task.done && x.task.due && x.task.due < today && ruleOf(x.task) === null,
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
    const rule = ruleOf(t);
    if (done && t.due && rule) {
      let next = step(t.due, rule);
      const today = dayKey(now);
      while (next && next <= today) next = step(next, rule);
      if (!next) {
        t.done = true;
        t.doneAt = now;
        return t;
      }
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
  const PLURAL = {
    sundays: 0, niedziele: 0,
    mondays: 1, poniedzialki: 1, poniedziałki: 1,
    tuesdays: 2, wtorki: 2,
    wednesdays: 3, srody: 3, środy: 3,
    thursdays: 4, czwartki: 4,
    fridays: 5, piatki: 5, piątki: 5,
    saturdays: 6, soboty: 6,
  };
  const EVERY = [
    [/^(?:every\s+day|daily|codziennie|co\s+dzie[nń])$/, { every: 1, unit: "day" }],
    [/^(?:every\s+weekday|weekdays|w\s+dni\s+(?:robocze|powszednie))$/, { every: 1, unit: "week", days: [1, 2, 3, 4, 5] }],
    [/^(?:every\s+week|weekly|co\s+tydzie[nń]|cotygodniowo)$/, { every: 1, unit: "week" }],
    [/^(?:every\s+month|monthly|co\s+miesi[aą]c|comiesi[eę]cznie)$/, { every: 1, unit: "month" }],
    [/^(?:every\s+year|yearly|annually|co\s+rok|co\s+roku|corocznie)$/, { every: 1, unit: "year" }],
  ];
  const UNIT_WORDS = [
    [/^(?:days?|dni|dzie[nń])$/, "day"],
    [/^(?:weeks?|tygodnie|tygodni|tydzie[nń])$/, "week"],
    [/^(?:months?|miesi[aą]ce|miesi[eę]cy|miesi[aą]c)$/, "month"],
    [/^(?:years?|lata|lat|rok)$/, "year"],
  ];

  function dateWord(word, base) {
    if (parseDay(word)) return word;
    const m = word.match(/^(\d{1,2})[./](\d{1,2})(?:[./](\d{4}))?$/);
    if (!m) return null;
    const year = m[3] ? Number(m[3]) : base.getFullYear();
    const d = new Date(year, Number(m[2]) - 1, Number(m[1]));
    if (d.getMonth() !== Number(m[2]) - 1) return null;
    if (!m[3] && dayKey(d) < dayKey(base)) d.setFullYear(year + 1);
    return dayKey(d);
  }

  function quick(input, now) {
    const base = new Date(now === undefined ? Date.now() : now);
    let text = String(input || "").trim();
    let due = null;
    let time = null;
    let exact = null;
    let rule = null;
    const take = (re, fn) => {
      const m = text.match(re);
      if (!m) return;
      if (fn(m) === false) return;
      text = (text.slice(0, m.index) + " " + text.slice(m.index + m[0].length)).replace(/\s+/g, " ").trim();
    };
    const units = "days?|dni|dzie[nń]|weeks?|tygodnie|tygodni|tydzie[nń]|months?|miesi[aą]ce|miesi[eę]cy|miesi[aą]c|years?|lata|lat|rok";
    take(new RegExp("(?:^|\\s)(?:every|co)\\s+(\\d{1,3})\\s+(" + units + ")(?=\\s|$)", "i"), (m) => {
      rule = { every: Number(m[1]), unit: UNIT_WORDS.find((u) => u[0].test(m[2].toLowerCase()))[1] };
    });
    const phrases = "every\\s+day|daily|codziennie|co\\s+dzie[nń]|every\\s+weekday|weekdays|w\\s+dni\\s+(?:robocze|powszednie)|every\\s+week|weekly|co\\s+tydzie[nń]|cotygodniowo|every\\s+month|monthly|co\\s+miesi[aą]c|comiesi[eę]cznie|every\\s+year|yearly|annually|co\\s+roku|co\\s+rok|corocznie";
    if (!rule)
      take(new RegExp("(?:^|\\s)(" + phrases + ")(?=\\s|$)", "i"), (m) => {
        const hit = EVERY.find((e) => e[0].test(m[1].toLowerCase().replace(/\s+/g, " ")));
        rule = Object.assign({}, hit[1]);
      });
    const dayNames = Object.keys(PLURAL).concat(Object.keys(WEEKDAYS)).sort((a, b) => b.length - a.length).join("|");
    take(new RegExp("(?:^|\\s)(every|co|on|w|we)?\\s*((?:" + dayNames + ")(?:\\s*(?:,|and|i|&)\\s*(?:" + dayNames + "))*)(?=\\s|$)", "i"), (m) => {
      const words = m[2].toLowerCase().split(/\s*(?:,|\band\b|\bi\b|&)\s*/).filter(Boolean);
      const recurring = /^(every|co)$/i.test(m[1] || "") || words.some((w) => PLURAL[w] !== undefined) || (rule !== null && rule.unit === "week" && !rule.days);
      if (!recurring) return false;
      const days = words.map((w) => (PLURAL[w] !== undefined ? PLURAL[w] : WEEKDAYS[w]));
      rule = rule && rule.unit === "week" ? Object.assign({}, rule, { days: days }) : { every: 1, unit: "week", days: days };
    });
    if (rule)
      take(/(?:^|\s)(?:until|till|do)\s+(\d{4}-\d{2}-\d{2}|\d{1,2}[./]\d{1,2}(?:[./]\d{4})?)(?=\s|$)/i, (m) => {
        const until = dateWord(m[1], base);
        if (!until) return false;
        rule.until = until;
      });
    take(/(?:^|\s)(?:in|za)\s+(\d{1,3})\s*(min|mins|minutes|minut|m|h|hours|hour|godz|godzin|godziny)(?=\s|$)/i, (m) => {
      const n = Number(m[1]);
      exact = base.getTime() + (/^(h|hour|hours|godz|godzin|godziny)$/i.test(m[2]) ? n * 60 : n) * 60000;
    });
    take(/(?:^|\s)(now|teraz|right\s+now|zaraz)(?=\s|$)/i, () => {
      exact = base.getTime() + 60000;
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
      return { text: text, due: dayKey(d), time: String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0"), rule: validRule(rule) };
    }
    if (rule && !due) due = dayKey(base);
    if (rule && validRule(rule)) due = first(due, validRule(rule));
    if (time && !due) {
      const t = at(dayKey(base), time);
      const d = new Date(base);
      if (t <= base.getTime()) d.setDate(d.getDate() + 1);
      due = dayKey(d);
    }
    return { text: text, due: due, time: time, rule: validRule(rule) };
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

  return { DAY, REPEATS, ENERGY, UNITS, ruleOf, legacy, untilAfter, splitText, joinText, uid, dayKey, parseDay, isTime, at, migrate, tasks, find, step, occurrences, reminders, agenda, overdue, busyDays, complete, plain, merge3, quick };
})();

export const { DAY, REPEATS, ENERGY, UNITS, ruleOf, legacy, untilAfter, splitText, joinText, uid, dayKey, parseDay, isTime, at, migrate, tasks, find, step, occurrences, reminders, agenda, overdue, busyDays, complete, plain, merge3, quick } = api;
