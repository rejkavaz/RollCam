// screens_share.jsx — Video export suite.

function PreviewOverlay({ style }) {
  return (
    <div className="rc-grain rc-vignette" style={{ position: "relative", width: "100%", aspectRatio: "16/9", borderRadius: 14, overflow: "hidden",
      background: "radial-gradient(120% 120% at 40% 30%, #2A3243, #0C0F15)", border: "1px solid var(--rc-line)" }}>
      {style === "cinematic" && <div style={{ position: "absolute", inset: 0, background: "linear-gradient(115deg, rgba(76,125,240,.20), rgba(255,75,58,.34))", zIndex: 2 }} />}
      {style === "minimal" && (
        <span className="rc-mono" style={{ position: "absolute", top: 12, right: 14, fontSize: 22, fontWeight: 600, color: "#fff", zIndex: 3, textShadow: "0 1px 6px rgba(0,0,0,.5)" }}>178</span>
      )}
      {style === "coach" && (
        <div style={{ position: "absolute", top: 12, right: 14, zIndex: 3, padding: "6px 11px", borderRadius: 11, background: "rgba(10,12,16,.55)", backdropFilter: "blur(10px)", border: "1px solid rgba(255,255,255,.16)", display: "flex", alignItems: "center", gap: 8 }}>
          <span className="rc-beat" style={{ width: 7, height: 7, borderRadius: "50%", background: "var(--rc-hr)" }} />
          <span className="rc-mono" style={{ fontSize: 14, fontWeight: 600, color: "#fff" }}>178</span>
          <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-z4)" }}>Z4</span>
        </div>
      )}
      {style === "data" && (
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, zIndex: 3, height: 34, background: "rgba(10,12,16,.6)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", gap: 10, padding: "0 12px" }}>
          <span className="rc-mono" style={{ fontSize: 12, fontWeight: 600, color: "var(--rc-hr)" }}>178 bpm</span>
          <span className="rc-mono" style={{ fontSize: 10, color: "rgba(255,255,255,.6)" }}>ZONE 4</span>
          <svg width="80" height="18" style={{ marginLeft: "auto" }}><polyline points="0,13 10,9 20,11 30,4 40,8 50,3 62,7 72,4 80,6" fill="none" stroke="var(--rc-hr)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </div>
      )}
      <span className="rc-mono" style={{ position: "absolute", bottom: 10, left: 12, fontSize: 9, color: "rgba(255,255,255,.4)", zIndex: 3 }}>{style === "data" ? "" : "R2 · 03:18"}</span>
    </div>
  );
}

function ExportSuite({ back, params }) {
  const [style, setStyle] = useState("cinematic");
  const [layout, setLayout] = useState("side");
  const [blur, setBlur] = useState(true);
  const styles = [["minimal", "Minimal", "HR number only"], ["coach", "Coach", "badge + zone"], ["cinematic", "Cinematic", "tint shifts with HR"], ["data", "Data-heavy", "caption + graph"]];
  const layouts = [["side", "Side-by-side", "video + scrolling HR graph", "layers"], ["lapse", "Timelapse", "5 min → 30s, graph racing", "film"], ["cap", "Subtitle caption", "HR + zone bottom bar", "captions"]];
  return (
    <div className="rc-view">
      <Header onBack={back} eyebrow="Export · R2 highlight · 0:30" right={<IconBtn name="share" />} />
      <div style={{ padding: "0 20px 40px", display: "flex", flexDirection: "column", gap: 18 }}>
        <h1 className="rc-h1" style={{ marginTop: -4 }}>Share clip</h1>
        <PreviewOverlay style={style} />

        {/* style picker */}
        <div>
          <span className="rc-eyebrow">Overlay style</span>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginTop: 12 }}>
            {styles.map(([id, name, desc]) => {
              const on = style === id;
              return (
                <button key={id} className="rc-tap" onClick={() => setStyle(id)} style={{ textAlign: "left", padding: 12, borderRadius: 14, cursor: "pointer",
                  background: on ? "var(--rc-hr-dim)" : "var(--rc-surface-2)", border: "1px solid " + (on ? "var(--rc-hr)" : "var(--rc-line)") }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontSize: 14, fontWeight: 600, color: "var(--rc-text)" }}>{name}</span>
                    {on && <Icon name="check" size={16} color="var(--rc-hr)" />}
                  </div>
                  <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)", marginTop: 4, display: "block" }}>{desc}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* layout radios */}
        <div>
          <span className="rc-eyebrow">Layout</span>
          <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 12 }}>
            {layouts.map(([id, name, desc, icon]) => {
              const on = layout === id;
              return (
                <button key={id} className="rc-tap" onClick={() => setLayout(id)} style={{ padding: "12px 14px", borderRadius: 14, cursor: "pointer", display: "flex", alignItems: "center", gap: 12,
                  background: "var(--rc-surface)", border: "1px solid " + (on ? "var(--rc-line-2)" : "var(--rc-line)") }}>
                  <Icon name={icon} size={19} color={on ? "var(--rc-text)" : "var(--rc-text-3)"} />
                  <div style={{ flex: 1, textAlign: "left", display: "flex", flexDirection: "column", gap: 3 }}>
                    <span style={{ fontSize: 14, fontWeight: 600, color: "var(--rc-text)" }}>{name}</span>
                    <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)" }}>{desc}</span>
                  </div>
                  <span style={{ width: 20, height: 20, borderRadius: "50%", border: "2px solid " + (on ? "var(--rc-hr)" : "var(--rc-line-2)"), background: on ? "var(--rc-hr)" : "transparent", display: "flex", alignItems: "center", justifyContent: "center" }}>{on && <span style={{ width: 7, height: 7, borderRadius: "50%", background: "#fff" }} />}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* privacy */}
        <div className="rc-card-2" style={{ padding: "13px 14px", display: "flex", alignItems: "center", gap: 12 }}>
          <Icon name="eye-off" size={17} color="var(--rc-text-2)" />
          <div style={{ flex: 1 }}>
            <span style={{ fontSize: 14, fontWeight: 600 }}>Blur partners' faces</span>
            <div className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-3)", marginTop: 2 }}>on-device · before anything leaves the phone</div>
          </div>
          <button className="rc-tap" onClick={() => setBlur((v) => !v)} style={{ width: 46, height: 28, borderRadius: 999, border: "none", cursor: "pointer", position: "relative", background: blur ? "var(--rc-good)" : "var(--rc-surface-3)", transition: "background .2s" }}>
            <span style={{ position: "absolute", top: 3, left: blur ? 21 : 3, width: 22, height: 22, borderRadius: "50%", background: "#fff", transition: "left .2s" }} />
          </button>
        </div>

        <button className="rc-btn rc-btn-hr"><Icon name="download" size={18} color="#fff" /> Export clip</button>
        <div style={{ display: "flex", gap: 8, justifyContent: "center" }}>
          {["Save", "Instagram", "WhatsApp", "CSV"].map((d) => <span key={d} className="rc-pill" style={{ fontSize: 11 }}>{d}</span>)}
        </div>
      </div>
    </div>
  );
}

window.ExportSuite = ExportSuite;
