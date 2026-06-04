// screens_review.jsx — Post-session overview + Review & tag + Round comparison.
function parseDur(d) { const [m, s] = d.split(":").map(Number); return m * 60 + s; }
function getSession(params) { return RC_SESSIONS.find((x) => x.id === (params && params.id)) || RC_SESSIONS[0]; }

function PostSession({ nav, back, params }) {
  const s = getSession(params);
  const fresh = params && params.fresh;
  return (
    <div className="rc-view">
      <Header onBack={back} eyebrow={fresh ? "Saved · just now" : `${s.day} · ${s.date} · ${s.time}`}
        right={<IconBtn name="dots" />} />
      <div style={{ padding: "0 20px 40px", display: "flex", flexDirection: "column", gap: 16 }}>
        <h1 className="rc-h1" style={{ marginTop: -4 }}>{s.title}</h1>
        <span className="rc-mono" style={{ fontSize: 12, color: "var(--rc-text-3)", marginTop: -6 }}>{s.rounds} rounds · {s.duration} mat time</span>

        {/* session graph */}
        <div className="rc-card" style={{ padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <span className="rc-eyebrow">Heart rate</span>
            <span className="rc-mono" style={{ fontSize: 11, color: "var(--rc-hr)" }}>peak {s.peak} bpm</span>
          </div>
          <HRGraph series={s.series} w={300} h={96} markers={(s.tagged || []).map((t) => ({ pos: t.pos }))} animate />
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10 }}>
            <span className="rc-mono" style={{ fontSize: 9.5, color: "var(--rc-text-3)" }}>0:00</span>
            <span className="rc-mono" style={{ fontSize: 9.5, color: "var(--rc-text-3)" }}>{s.duration}</span>
          </div>
        </div>

        {/* stats */}
        <div style={{ display: "flex", gap: 10 }}>
          <StatTile label="Peak HR" value={s.peak} unit="bpm" accent />
          <StatTile label="Avg HR" value={s.avg} unit="bpm" />
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <StatTile label="Recovery" value={s.recovery} unit="bpm/m" />
          <StatTile label="Zone 4+" value={s.zone4} unit="min" />
        </div>

        {/* AI summary */}
        <div className="rc-card" style={{ padding: 16, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 3, background: "var(--rc-hr)" }} />
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
            <Icon name="sparkles" size={14} color="var(--rc-hr)" />
            <span className="rc-eyebrow">Coaching summary</span>
          </div>
          <p style={{ margin: 0, fontSize: 14, lineHeight: 1.55, color: "var(--rc-text)" }}>{s.ai}</p>
        </div>

        {/* pressure moments */}
        {s.pressure && <>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 2 }}>
            <span className="rc-eyebrow">Pressure moments</span>
            <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)" }}>{s.pressure.length} found</span>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {s.pressure.map((p, i) => (
              <div key={i} className="rc-card-2 rc-tap" onClick={() => nav("reviewtag", { id: s.id })} style={{ padding: 10, display: "flex", alignItems: "center", gap: 12 }}>
                <Thumb size={46} />
                <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 3 }}>
                  <span className="rc-mono" style={{ fontSize: 12, fontWeight: 600 }}>{p.r}</span>
                  <span style={{ fontSize: 12, color: "var(--rc-text-3)" }}>{p.note}</span>
                </div>
                <Icon name="play" size={15} color="var(--rc-text-2)" />
              </div>
            ))}
          </div>
        </>}

        <div style={{ display: "flex", gap: 10, marginTop: 2 }}>
          <button className="rc-btn rc-btn-ghost" style={{ flex: 1, fontSize: 13.5 }} onClick={() => nav("reviewtag", { id: s.id })}><Icon name="tag" size={17} /> Review & tag</button>
          <button className="rc-btn rc-btn-ghost" style={{ flex: 1, fontSize: 13.5 }} onClick={() => nav("compare", { id: s.id })}><Icon name="activity" size={17} /> Compare</button>
        </div>
        <button className="rc-btn rc-btn-hr" onClick={() => nav("export", { id: s.id })}><Icon name="sparkles" size={18} color="#fff" /> Build highlight reel</button>
      </div>
    </div>
  );
}

/* ---------------- Review & tag ---------------- */
function ReviewTag({ back, params }) {
  const s = getSession(params);
  const dur = parseDur(s.duration);
  const [ph, setPh] = useState(0.46);
  const [tags, setTags] = useState(() => [...(s.tagged || [])]);
  const wrapRef = useRef(null);
  const n = s.series.length;
  const bpmAt = Math.round(s.series[Math.round(ph * (n - 1))]);
  const tagOpts = [["Submission", "swords"], ["Sweep", "flip"], ["Bad pos", "shield"], ["Scramble", "zap"], ["Tap", "check"]];

  const scrub = (clientX) => {
    const r = wrapRef.current.getBoundingClientRect();
    setPh(Math.max(0, Math.min(1, (clientX - r.left) / r.width)));
  };
  const onDown = (e) => { scrub(e.clientX); const mv = (ev) => scrub(ev.clientX); const up = () => { window.removeEventListener("pointermove", mv); window.removeEventListener("pointerup", up); }; window.addEventListener("pointermove", mv); window.addEventListener("pointerup", up); };
  const addTag = (tag, icon) => {
    setTags((t) => [...t, { t: fmt(Math.round(ph * dur)), tag, icon, bpm: bpmAt, pos: ph }].sort((a, b) => a.pos - b.pos));
  };

  return (
    <div className="rc-view" style={{ minHeight: "100%" }}>
      {/* player */}
      <div className="rc-grain rc-vignette" style={{ position: "relative", height: 240, background: "radial-gradient(130% 100% at 50% 40%, #283041, #0B0E13)" }}>
        <div style={{ position: "absolute", top: 56, left: 18, zIndex: 3 }}>
          <button className="rc-tap" onClick={back} style={{ width: 34, height: 34, borderRadius: "50%", background: "rgba(10,12,16,.55)", backdropFilter: "blur(14px)", border: "1px solid rgba(255,255,255,.12)", color: "#fff", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="chevron-left" size={20} color="#fff" /></button>
        </div>
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", zIndex: 2 }}>
          <div style={{ width: 56, height: 56, borderRadius: "50%", background: "rgba(255,255,255,.16)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid rgba(255,255,255,.2)" }}>
            <Icon name="play" size={22} color="#fff" />
          </div>
        </div>
        <span className="rc-mono" style={{ position: "absolute", bottom: 14, left: 18, fontSize: 12, color: "#fff", zIndex: 3 }}>{fmt(Math.round(ph * dur))} <span style={{ color: "rgba(255,255,255,.5)" }}>/ {s.duration}</span></span>
        <span className="rc-mono" style={{ position: "absolute", bottom: 14, right: 18, fontSize: 12, color: "var(--rc-hr)", zIndex: 3, fontWeight: 600 }}>{bpmAt} bpm</span>
      </div>

      <div style={{ padding: "18px 20px 40px", display: "flex", flexDirection: "column", gap: 18 }}>
        {/* scrubber */}
        <div className="rc-card" style={{ padding: "14px 14px 10px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
            <span className="rc-eyebrow">Scrub · HR synced</span>
            <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)" }}>drag the line</span>
          </div>
          <div ref={wrapRef} onPointerDown={onDown} style={{ cursor: "ew-resize", touchAction: "none" }}>
            <HRGraph series={s.series} w={298} h={78} playhead={ph} markers={tags.map((t) => ({ pos: t.pos }))} grid={false} />
          </div>
        </div>

        {/* tag drop */}
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <span className="rc-eyebrow">Tap to tag</span>
            <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)" }}>drops at {fmt(Math.round(ph * dur))}</span>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            {tagOpts.map(([tag, icon]) => (
              <button key={tag} className="rc-tap" onClick={() => addTag(tag, icon)} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 7, padding: "12px 2px", borderRadius: 13, background: "var(--rc-surface-2)", border: "1px solid var(--rc-line)", cursor: "pointer", color: "var(--rc-text-2)" }}>
                <Icon name={icon} size={19} color="var(--rc-text)" />
                <span className="rc-mono" style={{ fontSize: 8, letterSpacing: ".02em" }}>{tag.toUpperCase()}</span>
              </button>
            ))}
          </div>
        </div>

        {/* tagged list */}
        <div>
          <span className="rc-eyebrow">Tagged moments · {tags.length}</span>
          <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 12 }}>
            {tags.map((t, i) => (
              <div key={i} className="rc-card-2" style={{ padding: "10px 12px", display: "flex", alignItems: "center", gap: 11 }}>
                <Icon name={t.icon} size={16} color="var(--rc-text-2)" />
                <span className="rc-mono" style={{ fontSize: 12, width: 44 }}>{t.t}</span>
                <span style={{ flex: 1, fontSize: 13 }}>{t.tag}</span>
                <span className="rc-mono" style={{ fontSize: 12, color: "var(--rc-hr)", fontWeight: 600 }}>{t.bpm} bpm</span>
              </div>
            ))}
          </div>
        </div>

        <button className="rc-btn rc-btn-soft" style={{ borderStyle: "dashed" }}><Icon name="mic" size={17} /> Hold to add 30s voice note</button>
      </div>
    </div>
  );
}

/* ---------------- Round comparison ---------------- */
function RoundCompare({ back, params }) {
  const s = getSession({ id: "s1" });
  const curves = s.roundCurves;
  const [hidden, setHidden] = useState({});
  return (
    <div className="rc-view">
      <Header onBack={back} eyebrow={`${s.title} · ${s.rounds} rounds`} right={<div style={{ width: 36 }} />} />
      <div style={{ padding: "0 20px 40px", display: "flex", flexDirection: "column", gap: 16 }}>
        <h1 className="rc-h1" style={{ marginTop: -4 }}>Round comparison</h1>

        {/* overlaid graph */}
        <div className="rc-card" style={{ padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <span className="rc-eyebrow">HR per round · overlaid</span>
            <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)" }}>0:00 – 5:00</span>
          </div>
          <div style={{ position: "relative", width: 298, height: 158 }}>
            {curves.map((c, i) => !hidden[c.label] && (
              <div key={i} style={{ position: "absolute", inset: 0 }}>
                <HRGraph series={c.series} w={298} h={158} min={140} max={198} stroke={c.color} fill={i === 0}
                  area="var(--rc-hr)" grid={i === 0} strokeW={i === 0 ? 2.6 : 2} />
              </div>
            ))}
          </div>
        </div>

        {/* legend toggles */}
        <div style={{ display: "flex", gap: 10 }}>
          {curves.map((c) => {
            const off = hidden[c.label];
            return (
              <button key={c.label} className="rc-tap" onClick={() => setHidden((h) => ({ ...h, [c.label]: !h[c.label] }))} style={{ flex: 1, padding: "11px 10px", borderRadius: 13, background: "var(--rc-surface-2)", border: "1px solid var(--rc-line)", cursor: "pointer", display: "flex", flexDirection: "column", gap: 7, opacity: off ? 0.4 : 1 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                  <span style={{ width: 16, height: 3, borderRadius: 2, background: c.color }} />
                  <span className="rc-mono" style={{ fontSize: 12, fontWeight: 600, color: "var(--rc-text)" }}>{c.label}</span>
                </div>
                <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)", textAlign: "left" }}>peak {c.peak}</span>
              </button>
            );
          })}
        </div>

        {/* insight */}
        <div className="rc-card" style={{ padding: 16, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 3, background: "var(--rc-hr)" }} />
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
            <Icon name="activity" size={14} color="var(--rc-hr)" />
            <span className="rc-eyebrow">Fatigue signature</span>
          </div>
          <p style={{ margin: 0, fontSize: 14, lineHeight: 1.55 }}>Peak HR dropped <span className="rc-mono" style={{ color: "var(--rc-hr)" }}>194 → 176</span> across rounds and your curve flattens earlier each round — a classic fatigue pattern.</p>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { PostSession, ReviewTag, RoundCompare });
