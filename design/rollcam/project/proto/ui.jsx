// ui.jsx — shared RollCam UI: HR data, graphs, stats, chrome.
const { useState, useEffect, useRef, useMemo } = React;

const RC_ZONES = ["--rc-z1","--rc-z2","--rc-z3","--rc-z4","--rc-z5"];
const ZONE_NAME = ["Recovery","Easy","Aerobic","Threshold","Max"];
function zoneIndex(bpm, max = 195) {
  const pct = bpm / max;
  if (pct < 0.62) return 0;
  if (pct < 0.72) return 1;
  if (pct < 0.82) return 2;
  if (pct < 0.90) return 3;
  return 4;
}
function zoneVar(i) { return `var(${RC_ZONES[i]})`; }

/* ---- live HR stream (wandering bpm + rolling history) ---------------- */
function useHRStream({ base = 172, swing = 22, len = 48, ms = 900, running = true } = {}) {
  const [bpm, setBpm] = useState(base);
  const [series, setSeries] = useState(() => Array.from({ length: len }, (_, i) =>
    base + Math.sin(i / 5) * swing * 0.5 + (Math.random() - 0.5) * 6));
  const cur = useRef(base);
  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => {
      const drift = (base - cur.current) * 0.08;
      cur.current = Math.max(120, Math.min(198, cur.current + drift + (Math.random() - 0.45) * 9));
      const b = Math.round(cur.current);
      setBpm(b);
      setSeries((s) => [...s.slice(1), cur.current]);
    }, ms);
    return () => clearInterval(id);
  }, [base, ms, running]);
  return { bpm, series };
}

/* ---- smooth path from normalized points ------------------------------ */
function smoothPath(pts) {
  if (pts.length < 2) return "";
  let d = `M ${pts[0][0].toFixed(1)} ${pts[0][1].toFixed(1)}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
    const c1x = p1[0] + (p2[0] - p0[0]) / 6, c1y = p1[1] + (p2[1] - p0[1]) / 6;
    const c2x = p2[0] - (p3[0] - p1[0]) / 6, c2y = p2[1] - (p3[1] - p1[1]) / 6;
    d += ` C ${c1x.toFixed(1)} ${c1y.toFixed(1)}, ${c2x.toFixed(1)} ${c2y.toFixed(1)}, ${p2[0].toFixed(1)} ${p2[1].toFixed(1)}`;
  }
  return d;
}

/* ---- HR graph -------------------------------------------------------- */
function HRGraph({ series, w, h, min = 120, max = 198, stroke = "var(--rc-hr)",
                  fill = true, area = "var(--rc-hr)", markers = [], playhead = null,
                  grid = true, animate = false, strokeW = 2.4, padTop = 10, padBot = 8, faint = false }) {
  const id = useMemo(() => "g" + Math.random().toString(36).slice(2, 8), []);
  const n = series.length;
  const pts = series.map((v, i) => {
    const x = (i / (n - 1)) * w;
    const t = Math.max(0, Math.min(1, (v - min) / (max - min)));
    const y = h - padBot - t * (h - padTop - padBot);
    return [x, y];
  });
  const line = smoothPath(pts);
  const areaD = line + ` L ${w} ${h} L 0 ${h} Z`;
  const pathRef = useRef(null);
  useEffect(() => {
    if (!animate || !pathRef.current) return;
    const L = pathRef.current.getTotalLength();
    pathRef.current.style.transition = "none";
    pathRef.current.style.strokeDasharray = L;
    pathRef.current.style.strokeDashoffset = L;
    pathRef.current.getBoundingClientRect();
    pathRef.current.style.transition = "stroke-dashoffset 1s cubic-bezier(.2,.7,.2,1)";
    pathRef.current.style.strokeDashoffset = 0;
  }, [animate, line]);

  const phX = playhead != null ? playhead * w : null;
  const phI = playhead != null ? Math.round(playhead * (n - 1)) : 0;
  const phY = playhead != null && pts[phI] ? pts[phI][1] : 0;

  return (
    <svg width={w} height={h} style={{ display: "block", overflow: "visible" }}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={area} stopOpacity={faint ? .14 : .26} />
          <stop offset="100%" stopColor={area} stopOpacity="0" />
        </linearGradient>
      </defs>
      {grid && [0.5, 1].map((b, i) => (
        <line key={i} x1="0" x2={w} y1={padTop + b * (h - padTop - padBot)} y2={padTop + b * (h - padTop - padBot)}
              stroke="var(--rc-line)" strokeWidth="1" />
      ))}
      {fill && <path d={areaD} fill={`url(#${id})`} />}
      <path ref={pathRef} d={line} fill="none" stroke={faint ? "var(--rc-text-3)" : stroke}
            strokeWidth={strokeW} strokeLinecap="round" strokeLinejoin="round" />
      {markers.map((m, i) => {
        const x = m.pos * w;
        return (
          <g key={i}>
            <line x1={x} x2={x} y1={padTop - 4} y2={h - 2} stroke="var(--rc-line-2)" strokeWidth="1" strokeDasharray="2 3" />
            <circle cx={x} cy={padTop - 2} r="9" fill="var(--rc-surface-3)" stroke={m.color || "var(--rc-text-2)"} strokeWidth="1.4" />
          </g>
        );
      })}
      {playhead != null && (
        <g>
          <line x1={phX} x2={phX} y1={padTop - 4} y2={h} stroke="var(--rc-text)" strokeWidth="1.5" opacity=".8" />
          <circle cx={phX} cy={phY} r="5" fill="var(--rc-hr)" stroke="#fff" strokeWidth="1.5" />
        </g>
      )}
    </svg>
  );
}

/* ---- zone distribution bar ------------------------------------------- */
function ZoneBar({ dist, h = 10, labels = false }) {
  const total = dist.reduce((a, b) => a + b, 0) || 1;
  return (
    <div>
      <div style={{ display: "flex", gap: 3, height: h }}>
        {dist.map((v, i) => v > 0 && (
          <div key={i} style={{ flex: v, background: zoneVar(i), borderRadius: 3, opacity: i >= 3 ? 1 : 0.85 }} />
        ))}
      </div>
      {labels && (
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8 }}>
          {dist.map((v, i) => (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <span style={{ width: 8, height: 8, borderRadius: 2, background: zoneVar(i) }} />
              <span className="rc-mono" style={{ fontSize: 9, color: "var(--rc-text-3)" }}>Z{i + 1}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* ---- stat tile ------------------------------------------------------- */
function StatTile({ label, value, unit, accent, trend, sub }) {
  return (
    <div className="rc-card-2" style={{ padding: "13px 14px", display: "flex", flexDirection: "column", gap: 7, flex: 1, minWidth: 0 }}>
      <span className="rc-eyebrow">{label}</span>
      <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
        <span className="rc-mono" style={{ fontSize: 26, fontWeight: 600, lineHeight: 1, color: accent ? "var(--rc-hr)" : "var(--rc-text)" }}>{value}</span>
        {unit && <span className="rc-mono" style={{ fontSize: 11, color: "var(--rc-text-3)" }}>{unit}</span>}
      </div>
      {(trend || sub) && <span className="rc-mono" style={{ fontSize: 10.5, color: trend ? "var(--rc-good)" : "var(--rc-text-3)" }}>{trend || sub}</span>}
    </div>
  );
}

/* ---- top header (custom) --------------------------------------------- */
function Header({ title, eyebrow, onBack, right, large }) {
  return (
    <div style={{ padding: "56px 20px 14px", display: "flex", flexDirection: "column", gap: large ? 10 : 6 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", minHeight: 28 }}>
        {onBack ? (
          <button className="rc-tap" onClick={onBack} style={{ background: "var(--rc-surface-2)", border: "1px solid var(--rc-line)", width: 36, height: 36, borderRadius: 11, display: "flex", alignItems: "center", justifyContent: "center", color: "var(--rc-text)", cursor: "pointer" }}>
            <Icon name="chevron-left" size={20} />
          </button>
        ) : <div style={{ width: 36 }} />}
        {eyebrow && !large && <span className="rc-eyebrow">{eyebrow}</span>}
        <div style={{ display: "flex", gap: 8 }}>{right || <div style={{ width: 36 }} />}</div>
      </div>
      {large && eyebrow && <span className="rc-eyebrow">{eyebrow}</span>}
      {title && <h1 className="rc-h1">{title}</h1>}
    </div>
  );
}

function IconBtn({ name, onClick, active }) {
  return (
    <button className="rc-tap" onClick={onClick} style={{
      background: active ? "var(--rc-text)" : "var(--rc-surface-2)", border: "1px solid var(--rc-line)",
      width: 36, height: 36, borderRadius: 11, display: "flex", alignItems: "center", justifyContent: "center",
      color: active ? "#0A0C10" : "var(--rc-text)", cursor: "pointer", flex: "0 0 auto" }}>
      <Icon name={name} size={19} />
    </button>
  );
}

/* ---- bottom tab bar -------------------------------------------------- */
function TabBar({ active, onTab, onRec }) {
  const tabs = [["rolls","list","Rolls"], ["stats","bars","Stats"]];
  const Tab = ({ id, icon, label }) => (
    <button className="rc-tap" onClick={() => onTab(id)} style={{
      flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 5,
      background: "none", border: "none", cursor: "pointer", padding: "6px 0",
      color: active === id ? "var(--rc-text)" : "var(--rc-text-3)" }}>
      <Icon name={icon} size={23} strokeWidth={active === id ? 2.2 : 1.8} />
      <span className="rc-mono" style={{ fontSize: 9, letterSpacing: ".08em", textTransform: "uppercase" }}>{label}</span>
    </button>
  );
  return (
    <div style={{ flex: "0 0 auto", position: "relative", paddingBottom: 26, paddingTop: 10,
      background: "linear-gradient(to top, var(--rc-bg) 70%, transparent)", borderTop: "1px solid var(--rc-line)",
      display: "flex", alignItems: "center" }}>
      <Tab id="rolls" icon="list" label="Rolls" />
      <button className="rc-tap" onClick={onRec} style={{
        width: 60, height: 60, borderRadius: "50%", background: "var(--rc-hr)", border: "4px solid var(--rc-bg)",
        boxShadow: "0 6px 24px rgba(255,75,58,.4)", display: "flex", alignItems: "center", justifyContent: "center",
        cursor: "pointer", marginTop: -22, flex: "0 0 auto", color: "#fff" }}>
        <Icon name="video" size={26} color="#fff" />
      </button>
      <Tab id="stats" icon="bars" label="Stats" />
    </div>
  );
}

/* ---- segmented control ----------------------------------------------- */
function Segmented({ options, value, onChange }) {
  return (
    <div style={{ display: "flex", background: "var(--rc-surface-2)", border: "1px solid var(--rc-line)", borderRadius: 12, padding: 3, gap: 3 }}>
      {options.map((o) => (
        <button key={o.v} className="rc-tap" onClick={() => onChange(o.v)} style={{
          flex: 1, padding: "8px 6px", borderRadius: 9, border: "none", cursor: "pointer",
          fontFamily: "var(--rc-mono)", fontSize: 11.5, fontWeight: 600, letterSpacing: ".02em",
          background: value === o.v ? "var(--rc-surface-3)" : "transparent",
          color: value === o.v ? "var(--rc-text)" : "var(--rc-text-3)" }}>{o.l}</button>
      ))}
    </div>
  );
}

Object.assign(window, {
  RC_ZONES, ZONE_NAME, zoneIndex, zoneVar, useHRStream, HRGraph, ZoneBar,
  StatTile, Header, IconBtn, TabBar, Segmented, smoothPath,
});
