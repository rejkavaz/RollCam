// screen_record.jsx — Live camera + HR overlay, portrait & landscape.

function HRoverlay({ compact }) {
  return (
    <div className="box" style={{
      background: "rgba(255,255,255,.92)", borderColor: "var(--wf-hr)",
      padding: compact ? "6px 9px" : "8px 11px", display: "flex",
      alignItems: "center", gap: 9, backdropFilter: "blur(2px)"
    }}>
      <span className="hr-dot" />
      <div className="col" style={{ gap: 1 }}>
        <div className="row aic gap-2">
          <span className="hr-num" style={{ fontSize: compact ? 24 : 30 }}>178</span>
          <span className="wf-mono" style={{ fontSize: 10, color: "var(--wf-ink-3)" }}>bpm</span>
        </div>
        <span className="zone-tag" style={{ alignSelf: "flex-start" }}>ZONE 4 · HARD</span>
      </div>
      <svg width="58" height="30" style={{ marginLeft: 2 }}>
        <polyline points="0,22 8,18 14,24 22,10 30,14 38,4 46,12 52,7 58,11"
          fill="none" stroke="var(--wf-hr)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </div>
  );
}

function RecCtrl({ glyph, label, big, danger }) {
  return (
    <div className="col center" style={{ gap: 5, width: big ? 64 : 46 }}>
      <div style={{
        width: big ? 58 : 40, height: big ? 58 : 40, borderRadius: "50%",
        border: "2px solid " + (danger ? "var(--wf-hr)" : "var(--wf-ink)"),
        background: danger ? "var(--wf-hr)" : "rgba(255,255,255,.85)",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontFamily: "var(--wf-mono)", fontSize: big ? 18 : 14,
        color: danger ? "#fff" : "var(--wf-ink)"
      }}>{danger ? "■" : glyph}</div>
      <span className="wf-mono" style={{ fontSize: 8, color: "rgba(255,255,255,.95)", textShadow: "0 1px 2px rgba(0,0,0,.4)" }}>{label}</span>
    </div>
  );
}

function RecordPortrait() {
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={690}>
        <div style={{ position: "relative", flex: 1, minHeight: 0 }}>
          {/* camera viewport */}
          <div className="media" style={{ position: "absolute", inset: 0, borderRadius: 0, borderLeft: "none", borderRight: "none" }}>
            <span>CAMERA VIEW · LIVE</span>
          </div>

          {/* top status row */}
          <NoteBadge n="1" style={{ top: 10, left: 10 }} />
          <div style={{ position: "absolute", top: 12, left: 14, right: 14, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div className="box" style={{ background: "rgba(255,255,255,.9)", padding: "5px 10px", display: "flex", alignItems: "center", gap: 7 }}>
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: "var(--wf-hr)" }} />
              <span className="wf-mono" style={{ fontSize: 12, fontWeight: 600, color: "var(--wf-ink)" }}>REC 02:14</span>
            </div>
            <div className="pill wf-mono" style={{ background: "rgba(255,255,255,.9)", fontSize: 11 }}>ROUND 2 / 3</div>
          </div>

          {/* HR overlay */}
          <NoteBadge n="2" style={{ top: 56, right: 10 }} />
          <div style={{ position: "absolute", top: 60, right: 14 }}><HRoverlay /></div>

          {/* strap status */}
          <div className="box"
               style={{ position: "absolute", top: 132, right: 14, background: "rgba(255,255,255,.85)", padding: "3px 8px" }}>
            <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-2)" }}>◧ Polar H10 · connected</span>
          </div>

          {/* live zone strip (left edge) */}
          <NoteBadge n="3" style={{ bottom: 96, left: 10 }} />
          <div style={{ position: "absolute", left: 14, bottom: 92, display: "flex", flexDirection: "column", gap: 3 }}>
            {["Z5","Z4","Z3","Z2","Z1"].map((z, i) => (
              <div key={z} className="wf-mono" style={{
                fontSize: 9, padding: "2px 6px", borderRadius: 3, width: 34, textAlign: "center",
                background: i === 1 ? "var(--wf-hr)" : "rgba(255,255,255,.7)",
                color: i === 1 ? "#fff" : "var(--wf-ink-3)",
                border: "1px solid " + (i === 1 ? "var(--wf-hr)" : "var(--wf-line-2)")
              }}>{z}</div>
            ))}
          </div>

          {/* bottom controls */}
          <NoteBadge n="4" style={{ bottom: 30, left: 10 }} />
          <div style={{ position: "absolute", left: 0, right: 0, bottom: 22, display: "flex", justifyContent: "center", alignItems: "center", gap: 26 }}>
            <RecCtrl glyph="⟲" label="FLIP" />
            <RecCtrl big danger label="STOP" />
            <RecCtrl glyph="❙❙" label="PAUSE" />
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Recording chrome is minimal — timer + round count top-left, never blocks the action in frame.",
        "HR is the hero overlay: live bpm, current zone, and a rolling sparkline. Burned into the footage so highlight clips already have it.",
        "Vertical zone strip gives an at-a-glance 'how hard am I going' read without looking at numbers.",
        "Only 3 controls while rolling — flip, stop, pause. No tagging here (tagging is post-review), so nothing competes with filming.",
      ]} />
    </div>
  );
}

function RecordLandscape() {
  return (
    <div className="wf col gap-4">
      <Phone w={700} h={330} land time="9:41">
        <div style={{ position: "relative", flex: 1, minHeight: 0 }}>
          <div className="media" style={{ position: "absolute", inset: 0, borderRadius: 0, borderLeft: "none", borderRight: "none" }}>
            <span>CAMERA VIEW · LANDSCAPE · the natural way BJJ footage is filmed</span>
          </div>

          {/* top-left status */}
          <div style={{ position: "absolute", top: 12, left: 16, display: "flex", gap: 10, alignItems: "center" }}>
            <div className="box" style={{ background: "rgba(255,255,255,.9)", padding: "5px 10px", display: "flex", alignItems: "center", gap: 7 }}>
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: "var(--wf-hr)" }} />
              <span className="wf-mono" style={{ fontSize: 12, fontWeight: 600, color: "var(--wf-ink)" }}>REC 02:14</span>
            </div>
            <div className="pill wf-mono" style={{ background: "rgba(255,255,255,.9)", fontSize: 11 }}>ROUND 2 / 3</div>
          </div>

          {/* HR overlay bottom-left (out of the way of the action) */}
          <NoteBadge n="1" style={{ bottom: 58, left: 12 }} />
          <div style={{ position: "absolute", bottom: 16, left: 16 }}><HRoverlay compact /></div>

          {/* controls stacked on the right thumb-side */}
          <NoteBadge n="2" style={{ top: 12, right: 78 }} />
          <div style={{ position: "absolute", right: 18, top: 0, bottom: 0, display: "flex", flexDirection: "column", justifyContent: "center", gap: 18 }}>
            <RecCtrl big danger label="STOP" />
            <RecCtrl glyph="❙❙" label="PAUSE" />
            <RecCtrl glyph="⟲" label="FLIP" />
          </div>
        </div>
      </Phone>

      <Notes w={700} items={[
        "Landscape mirrors portrait but re-flows the overlay to the bottom-left corner — keeps the center of the mat (where the roll happens) clear of UI.",
        "Controls move to a vertical stack on the right edge so they sit under the thumb when the phone is propped or held in two hands.",
      ]} />
    </div>
  );
}

Object.assign(window, { RecordPortrait, RecordLandscape });
