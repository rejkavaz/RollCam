// screen_export.jsx — Video export suite.

function StylePreview({ kind }) {
  // tiny mock of each overlay style inside a 16:9 frame
  return (
    <div className="media" style={{ width: "100%", height: 60, borderRadius: 6, position: "relative", overflow: "hidden" }}>
      <span style={{ position: "absolute", top: 4, left: 6, fontSize: 6, padding: 0 }}>video</span>
      {kind === "minimal" && (
        <div className="wf-mono" style={{ position: "absolute", top: 5, right: 6, fontSize: 11, fontWeight: 600, color: "var(--wf-hr)" }}>178</div>
      )}
      {kind === "coach" && (
        <div style={{ position: "absolute", top: 5, right: 6, background: "rgba(255,255,255,.85)", borderRadius: 4, padding: "2px 5px", border: "1px solid var(--wf-hr)" }}>
          <span className="wf-mono" style={{ fontSize: 9, fontWeight: 600, color: "var(--wf-hr)" }}>178 Z4</span>
        </div>
      )}
      {kind === "cinematic" && (
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(120deg, rgba(46,111,184,.18), rgba(226,87,76,.28))" }} />
      )}
      {kind === "data" && (
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 18, background: "rgba(255,255,255,.85)", display: "flex", alignItems: "center", padding: "0 5px", gap: 5 }}>
          <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-hr)", fontWeight: 600 }}>178 bpm</span>
          <svg width="60" height="12"><polyline points="0,9 8,6 16,8 24,3 32,6 40,2 48,5 60,3" fill="none" stroke="var(--wf-hr)" strokeWidth="1.5"/></svg>
        </div>
      )}
    </div>
  );
}

function ExportSuite() {
  const styles = [["minimal","Minimal","HR number only"],["coach","Coach","badge + zone"],["cinematic","Cinematic","tint shifts with HR"],["data","Data-heavy","caption + graph"]];
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={820}>
        <div className="col" style={{ flex: 1, minHeight: 0, padding: "16px 16px", gap: 16, overflow: "hidden" }}>
          <div className="col" style={{ gap: 3 }}>
            <span className="eyebrow">Export · R2 highlight · 0:30</span>
            <span className="h-title" style={{ fontSize: 20 }}>Overlay style</span>
          </div>

          {/* style picker grid */}
          <NoteBadge n="1" style={{ top: 70, left: 12 }} />
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            {styles.map((s, i) => (
              <div key={i} className="box col" style={{ padding: 8, gap: 6, borderColor: i === 2 ? "var(--wf-hr)" : "var(--wf-line)", borderWidth: i === 2 ? 2 : 1 }}>
                <StylePreview kind={s[0]} />
                <div className="col" style={{ gap: 1 }}>
                  <span className="wf" style={{ fontSize: 12, fontWeight: 600, color: "var(--wf-ink)" }}>{s[1]}</span>
                  <span className="sub wf-mono" style={{ fontSize: 8 }}>{s[2]}</span>
                </div>
              </div>
            ))}
          </div>

          {/* layout options */}
          <NoteBadge n="2" style={{ top: 360, right: 14 }} />
          <div>
            <SecLabel>Layout</SecLabel>
            <div className="col gap-2">
              {[["Side-by-side","video + scrolling HR graph",true],["Timelapse","5 min → 30s, graph racing",false],["Subtitle caption","HR + zone bottom bar",false]].map((o,i)=>(
                <div key={i} className="box row between aic" style={{ padding: "9px 11px" }}>
                  <div className="col" style={{ gap: 2 }}>
                    <span className="wf" style={{ fontSize: 12, color: "var(--wf-ink)", fontWeight: 600 }}>{o[0]}</span>
                    <span className="sub wf-mono" style={{ fontSize: 9 }}>{o[1]}</span>
                  </div>
                  <div style={{ width: 18, height: 18, borderRadius: "50%", border: "2px solid " + (o[2] ? "var(--wf-hr)" : "var(--wf-line)"), background: o[2] ? "var(--wf-hr)" : "transparent" }} />
                </div>
              ))}
            </div>
          </div>

          {/* privacy */}
          <NoteBadge n="3" style={{ bottom: 118, left: 12 }} />
          <div className="box box--faint row between aic" style={{ padding: "9px 11px" }}>
            <span className="wf-mono" style={{ fontSize: 10, color: "var(--wf-ink-2)" }}>◌ Blur partners' faces</span>
            <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>on-device</span>
          </div>

          {/* share destinations */}
          <NoteBadge n="4" style={{ bottom: 26, right: 14 }} />
          <div className="col gap-2" style={{ marginTop: "auto" }}>
            <div className="btn btn--solid">Export clip</div>
            <div className="row gap-2 center">
              {["Save","Insta","WhatsApp","CSV"].map((d,i)=>(
                <span key={i} className="pill wf-mono" style={{ fontSize: 10 }}>{d}</span>
              ))}
            </div>
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Four overlay styles shown as live mini-previews, not just names — you see Minimal vs Coach vs Cinematic vs Data-heavy before committing.",
        "Cinematic is the standout: the frame tint shifts cool→warm as HR rises (preview shows the gradient). Layout options cover side-by-side, timelapse and subtitle exports.",
        "Privacy is first-class — on-device face blur is a toggle right in the export flow, before anything leaves the phone.",
        "One export action, then one-tap share targets including raw CSV — 'your data, your choice'.",
      ]} />
    </div>
  );
}

Object.assign(window, { ExportSuite });
