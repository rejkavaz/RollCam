// screen_post.jsx — Post-session analysis (overview) + Review & tag.

function Stat({ k, v, unit, accent }) {
  return (
    <div className="box box--faint col" style={{ padding: "9px 10px", gap: 3, flex: 1 }}>
      <span className="wf-mono" style={{ fontSize: 8, letterSpacing: ".1em", color: "var(--wf-ink-3)", textTransform: "uppercase" }}>{k}</span>
      <div className="row aic gap-1" style={{ alignItems: "baseline" }}>
        <span className="wf-mono" style={{ fontSize: 19, fontWeight: 600, color: accent ? "var(--wf-hr)" : "var(--wf-ink)" }}>{v}</span>
        <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>{unit}</span>
      </div>
    </div>
  );
}

function PostOverview() {
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={780}>
        <div className="col" style={{ flex: 1, minHeight: 0, padding: "14px 16px 16px", gap: 14, overflow: "hidden" }}>
          {/* header */}
          <div className="row between aic">
            <div className="col" style={{ gap: 3 }}>
              <span className="eyebrow">Tue · 21 May · 19:30</span>
              <span className="h-title" style={{ fontSize: 18 }}>Evening Roll</span>
              <span className="sub wf-mono" style={{ fontSize: 11 }}>3 rounds · 18:42 mat time</span>
            </div>
            <div className="icon icon--circle" style={{ width: 30, height: 30 }}>⋯</div>
          </div>

          {/* session graph */}
          <div>
            <SecLabel right="peak 194 bpm">Session heart rate</SecLabel>
            <div className="box" style={{ padding: "10px 8px 6px" }}>
              <HRGraph w={272} h={92} fill
                pts={[.25,.4,.55,.5,.7,.85,.78,.95,.8,.6,.45,.55,.72,.66,.9,.74,.5,.38,.6,.5]}
                markers={[{ t: .42, g: "⚔" }, { t: .73, g: "⚡" }]} />
              <div className="row between" style={{ marginTop: 4 }}>
                <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>0:00</span>
                <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>18:42</span>
              </div>
            </div>
          </div>

          {/* stats grid */}
          <div className="col gap-2">
            <div className="row gap-2">
              <Stat k="Peak HR" v="194" unit="bpm" accent />
              <Stat k="Avg HR" v="181" unit="bpm" />
            </div>
            <div className="row gap-2">
              <Stat k="Recovery" v="−22" unit="bpm/min" />
              <Stat k="Zone 4+" v="38" unit="min" />
            </div>
          </div>

          {/* AI coaching summary */}
          <div>
            <SecLabel right="AI">Coaching summary</SecLabel>
            <div className="box" style={{ padding: 12, borderLeft: "3px solid var(--wf-hr)" }}>
              <p className="wf" style={{ margin: 0, fontSize: 12.5, lineHeight: 1.5, color: "var(--wf-ink-2)" }}>
                "Your HR peaked at 3:20 into round 2 and didn't drop below 160 for the rest of the session — you likely gassed after that scramble."
              </p>
            </div>
          </div>

          {/* pressure moments */}
          <div>
            <SecLabel right="3 found">Pressure moments</SecLabel>
            <div className="col gap-2">
              {[["R2 · 3:20", "Scramble — HR 188→194"], ["R3 · 1:05", "Heavy pressure, stuck"]].map((m, i) => (
                <div key={i} className="box row between aic" style={{ padding: "8px 10px" }}>
                  <div className="row aic gap-2">
                    <div className="media" style={{ width: 38, height: 26, borderRadius: 4 }}><span style={{ fontSize: 7, padding: 0 }}>clip</span></div>
                    <div className="col" style={{ gap: 2 }}>
                      <span className="wf-mono" style={{ fontSize: 10, fontWeight: 600, color: "var(--wf-ink)" }}>{m[0]}</span>
                      <span className="sub" style={{ fontSize: 10 }}>{m[1]}</span>
                    </div>
                  </div>
                  <span className="wf-mono" style={{ color: "var(--wf-ink-3)" }}>▶</span>
                </div>
              ))}
            </div>
          </div>

          <div className="btn btn--solid" style={{ marginTop: "auto" }}>▣ Build auto-highlight reel</div>
        </div>
      </Phone>

      <Notes items={[
        "Graph is the anchor — full-session HR curve with peak called out and post-review tags pinned as markers right on the line.",
        "Four stats that matter most for a fighter: peak, average, recovery rate, time in hard zones. Recovery & peak get the HR accent.",
        "AI coaching summary is one plain-language sentence, not a wall of charts. Accent rule on the left ties it to HR.",
        "Pressure Detector surfaces 2–3 auto-found moments with a clip thumb — tapping jumps into the review screen.",
        "Single primary action at the bottom: turn peaks into a highlight reel.",
      ]} />
    </div>
  );
}

function ReviewTag() {
  const tags = [["⚔","SUB"], ["⟳","SWEEP"], ["⛊","BAD POS"], ["⚡","SCRAMBLE"], ["✓","TAP"]];
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={690}>
        <div className="col" style={{ flex: 1, minHeight: 0 }}>
          {/* player */}
          <NoteBadge n="1" style={{ top: 38, left: 12 }} />
          <div className="media" style={{ height: 200, borderRadius: 0, borderLeft: "none", borderRight: "none", borderTop: "none" }}>
            <span>VIDEO PLAYBACK</span>
          </div>

          <div className="col" style={{ flex: 1, minHeight: 0, padding: 16, gap: 14 }}>
            {/* synced scrubber: HR line + playhead */}
            <NoteBadge n="2" style={{ top: 224, right: 18 }} />
            <div className="box" style={{ padding: "8px 8px 6px", position: "relative" }}>
              <HRGraph w={256} h={64}
                pts={[.3,.45,.4,.6,.78,.7,.9,.82,.6,.5,.65,.55,.7,.6,.85,.7]}
                markers={[{ t: .28, g: "⚔" }, { t: .62, g: "⚡" }]} />
              {/* playhead */}
              <div style={{ position: "absolute", top: 6, bottom: 18, left: "46%", width: 2, background: "var(--wf-ink)" }} />
              <div className="row between" style={{ marginTop: 4 }}>
                <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink)", fontWeight: 600 }}>03:18</span>
                <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>178 bpm</span>
              </div>
            </div>

            {/* tag drop */}
            <NoteBadge n="3" style={{ top: 360, left: 12 }} />
            <div>
              <SecLabel right="drops at playhead">Tap to tag</SecLabel>
              <div className="row gap-2" style={{ flexWrap: "wrap" }}>
                {tags.map((t, i) => (
                  <div key={i} className="box col center" style={{ width: 52, padding: "8px 0", gap: 4, borderStyle: i === 2 ? "solid" : "dashed", borderColor: i === 2 ? "var(--wf-hr)" : "var(--wf-line)" }}>
                    <span className="wf-mono" style={{ fontSize: 14, color: i === 2 ? "var(--wf-hr)" : "var(--wf-ink-2)" }}>{t[0]}</span>
                    <span className="wf-mono" style={{ fontSize: 7, color: "var(--wf-ink-3)" }}>{t[1]}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* tag timeline */}
            <NoteBadge n="4" style={{ bottom: 86, left: 12 }} />
            <div>
              <SecLabel>Tagged moments</SecLabel>
              <div className="col gap-2">
                {[["00:42","SWEEP","152 bpm"],["03:18","BAD POS","178 bpm"]].map((r,i) => (
                  <div key={i} className="box row between aic" style={{ padding: "7px 10px" }}>
                    <div className="row aic gap-2">
                      <span className="wf-mono" style={{ fontSize: 10, color: "var(--wf-ink)" }}>{r[0]}</span>
                      <span className="pill wf-mono" style={{ fontSize: 9, padding: "1px 7px" }}>{r[1]}</span>
                    </div>
                    <span className="wf-mono" style={{ fontSize: 10, color: "var(--wf-hr)" }}>{r[2]}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* voice note */}
            <div className="btn btn--ghost row center gap-2" style={{ marginTop: "auto" }}>
              <span className="wf-mono">●</span> Hold to add 30s voice note
            </div>
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Tagging lives in review, not while rolling — you scrub the footage calmly afterward and drop labels.",
        "Scrubber fuses video + HR: drag the playhead and the bpm read-out tracks it, so you tag against context.",
        "Pre-set one-tap tags drop a marker at the current playhead. Text glyphs (no emoji) keep it neutral.",
        "Every tag carries the HR at that instant → later you can filter 'bad position above 170 bpm' across all sessions.",
      ]} />
    </div>
  );
}

Object.assign(window, { PostOverview, ReviewTag });
