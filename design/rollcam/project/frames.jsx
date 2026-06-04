// frames.jsx — shared wireframe primitives for RollCam.
// Exports to window so other text/babel scripts can use them.
const { useId } = React;

/* ---- iPhone frame ---------------------------------------------------- */
function Phone({ w = 320, h = 690, land = false, time = "9:41", children, style }) {
  return (
    <div className={"phone wf" + (land ? " phone--land" : "")}
         style={{ width: w, height: h, ...style }}>
      <div className="statusbar">
        <span>{time}</span>
        <span className="dots"><i/><i/></span>
      </div>
      <div className="screen">{children}</div>
    </div>
  );
}

/* ---- annotation panel beside an artboard ----------------------------- */
function Notes({ items, w = 230 }) {
  return (
    <div className="wf col gap-3" style={{ width: w, paddingTop: 30 }}>
      <div className="eyebrow" style={{ color: "var(--wf-note)" }}>Notes</div>
      {items.map((t, i) => (
        <div className="note" key={i}>
          <span className="num">{i + 1}</span>
          <span>{t}</span>
        </div>
      ))}
    </div>
  );
}
function NoteBadge({ n, style }) {
  return <span className="note-badge" style={style}>{n}</span>;
}

/* ---- skeleton text block --------------------------------------------- */
function Lines({ widths = ["w-90", "w-60"], gap = 6, dk }) {
  return (
    <div className="col" style={{ gap }}>
      {widths.map((w, i) => <div key={i} className={"line " + w + (dk ? " dk" : "")} />)}
    </div>
  );
}

/* ---- bottom tab bar -------------------------------------------------- */
function TabBar({ active = 0 }) {
  const tabs = [
    { g: "▦", l: "HOME" },
    { g: "≣", l: "ROLLS" },
    { g: "●", l: "REC", big: true },
    { g: "◧", l: "STATS" },
    { g: "◔", l: "READY" },
  ];
  return (
    <div className="tabbar">
      {tabs.map((t, i) => (
        <div key={i} className={"tab" + (i === active ? " on" : "")}>
          <span className={"icon" + (t.big ? " icon--circle" : "")}
                style={t.big ? { borderColor: "var(--wf-hr)", color: "var(--wf-hr)", borderWidth: 2 } : null}>{t.g}</span>
          <span>{t.l}</span>
        </div>
      ))}
    </div>
  );
}

/* ---- HR curve as a rough SVG sketch ---------------------------------- */
// pts: array of 0..1 y-values (0 = bottom). Draws a smooth-ish polyline.
function HRGraph({ w, h, pts, stroke = "var(--wf-hr)", fill = false, bands = true,
                   markers = [], dashed = false, padL = 0, strokeW = 2, faint = false }) {
  const xy = pts.map((p, i) => {
    const x = padL + (i / (pts.length - 1)) * (w - padL);
    const y = h - 6 - p * (h - 12);
    return [x, y];
  });
  const d = xy.map((p, i) => (i ? "L" : "M") + p[0].toFixed(1) + " " + p[1].toFixed(1)).join(" ");
  const area = d + ` L${w} ${h} L${padL} ${h} Z`;
  const col = faint ? "var(--wf-line)" : stroke;
  return (
    <svg width={w} height={h} style={{ display: "block" }}>
      {bands && [0.66, 0.33].map((b, i) => (
        <line key={i} x1={padL} x2={w} y1={h - 6 - b * (h - 12)} y2={h - 6 - b * (h - 12)}
              stroke="var(--wf-line-2)" strokeWidth="1" strokeDasharray="2 3" />
      ))}
      {fill && <path d={area} fill="var(--wf-hr-soft)" opacity={faint ? .4 : .55} />}
      <path d={d} fill="none" stroke={col} strokeWidth={strokeW}
            strokeLinejoin="round" strokeLinecap="round"
            strokeDasharray={dashed ? "5 4" : null} />
      {markers.map((m, i) => {
        const x = padL + (m.t) * (w - padL);
        return (
          <g key={i}>
            <line x1={x} x2={x} y1="4" y2={h - 4} stroke="var(--wf-note)" strokeWidth="1" strokeDasharray="2 2" opacity=".7"/>
            <circle cx={x} cy="9" r="6" fill="var(--wf-note)" />
            <text x={x} y="12.5" textAnchor="middle" fontSize="8" fontFamily="var(--wf-mono)" fill="#fff" fontWeight="600">{m.g}</text>
          </g>
        );
      })}
    </svg>
  );
}

/* ---- mini bar chart (zones / weekly) --------------------------------- */
function Bars({ w, h, vals, accentIdx = -1, gap = 6 }) {
  const n = vals.length;
  const bw = (w - gap * (n - 1)) / n;
  return (
    <svg width={w} height={h} style={{ display: "block" }}>
      {vals.map((v, i) => {
        const bh = Math.max(3, v * (h - 4));
        const accent = i === accentIdx;
        return <rect key={i} x={i * (bw + gap)} y={h - bh} width={bw} height={bh} rx="2"
                     fill={accent ? "var(--wf-hr)" : "var(--wf-fill)"}
                     stroke={accent ? "none" : "var(--wf-line-2)"} strokeWidth="1" />;
      })}
    </svg>
  );
}

/* section label inside a screen */
function SecLabel({ children, right }) {
  return (
    <div className="row between aic" style={{ marginBottom: 8 }}>
      <div className="eyebrow">{children}</div>
      {right && <div className="eyebrow" style={{ color: "var(--wf-ink-3)" }}>{right}</div>}
    </div>
  );
}

Object.assign(window, { Phone, Notes, NoteBadge, Lines, TabBar, HRGraph, Bars, SecLabel });
