// data.jsx — mock RollCam sessions + derived series.

// deterministic-ish wandering HR series
function genSeries(len, base, amp, seed = 1) {
  let s = seed; const rnd = () => (s = (s * 9301 + 49297) % 233280) / 233280;
  let cur = base - amp * 0.4;
  const out = [];
  for (let i = 0; i < len; i++) {
    const ramp = Math.min(1, i / (len * 0.25));
    const target = base - amp * 0.5 + amp * ramp + Math.sin(i / 6) * amp * 0.35;
    cur += (target - cur) * 0.25 + (rnd() - 0.45) * amp * 0.18;
    out.push(Math.max(120, Math.min(198, cur)));
  }
  return out;
}

const RC_SESSIONS = [
  {
    id: "s1", title: "Evening Roll", day: "Tue", date: "21 May", time: "19:30",
    duration: "18:42", rounds: 3, peak: 194, avg: 181, recovery: -22, zone4: 38,
    dist: [4, 10, 22, 34, 30], tags: ["Scramble", "Bad pos"],
    series: genSeries(60, 178, 30, 7),
    ai: "Your HR peaked at 3:20 into round 2 and didn't drop below 160 for the rest of the session — you likely gassed after that scramble.",
    pressure: [
      { r: "R2 · 3:20", note: "Scramble — HR 188→194", pos: 0.42 },
      { r: "R3 · 1:05", note: "Heavy pressure, stuck", pos: 0.78 },
    ],
    tagged: [
      { t: "00:42", tag: "Sweep", icon: "flip", bpm: 152, pos: 0.07 },
      { t: "03:18", tag: "Bad pos", icon: "shield", bpm: 178, pos: 0.30 },
      { t: "08:40", tag: "Scramble", icon: "zap", bpm: 191, pos: 0.46 },
      { t: "14:02", tag: "Submission", icon: "swords", bpm: 184, pos: 0.74 },
    ],
    roundCurves: [
      { label: "R1", peak: 194, series: genSeries(34, 184, 16, 3), color: "var(--rc-hr)" },
      { label: "R2", peak: 188, series: genSeries(34, 176, 14, 11), color: "var(--rc-text)" },
      { label: "R3", peak: 176, series: genSeries(34, 166, 16, 21), color: "var(--rc-text-3)" },
    ],
  },
  {
    id: "s2", title: "Open Mat", day: "Mon", date: "20 May", time: "12:10",
    duration: "42:10", rounds: 6, peak: 188, avg: 174, recovery: -19, zone4: 51,
    dist: [8, 16, 28, 30, 18], tags: ["Submission", "Sweep"],
    series: genSeries(60, 172, 28, 13),
  },
  {
    id: "s3", title: "Comp Class", day: "Sat", date: "18 May", time: "10:00",
    duration: "31:05", rounds: 5, peak: 191, avg: 178, recovery: -24, zone4: 44,
    dist: [5, 12, 24, 32, 27], tags: ["Scramble"],
    series: genSeries(60, 176, 30, 29),
  },
  {
    id: "s4", title: "Drilling", day: "Thu", date: "16 May", time: "18:00",
    duration: "24:30", rounds: 4, peak: 172, avg: 158, recovery: -27, zone4: 18,
    dist: [18, 30, 28, 16, 8], tags: ["Sweep"],
    series: genSeries(60, 156, 26, 5),
  },
];

const RC_WEEK = {
  sessions: 4, avgPeak: 181, avgRecovery: -22, zone4: 38,
  load: [40, 62, 50, 80, 70, 95, 60], loadScore: 312,
  trend: genSeries(48, 150, 60, 41).map((v, i, a) => 150 - (i / a.length) * 55 + Math.sin(i / 4) * 6),
};
const RC_BESTS = [
  { k: "PR peak HR", v: "194 bpm", icon: "flame" },
  { k: "Fastest recovery", v: "−31 bpm/min", icon: "arrow-down" },
  { k: "Longest Zone 5", v: "2:48", icon: "trophy" },
];

Object.assign(window, { RC_SESSIONS, RC_WEEK, RC_BESTS, genSeries });
