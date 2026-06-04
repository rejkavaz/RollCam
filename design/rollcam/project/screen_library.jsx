// screen_library.jsx — Session library / list of rolls.

function SessionCard({ date, title, dur, peak, zones, tags }) {
  return (
    <div className="box row gap-3" style={{ padding: 10 }}>
      <div className="media" style={{ width: 64, height: 64, flex: "0 0 auto" }}><span style={{ fontSize: 8 }}>clip</span></div>
      <div className="col" style={{ flex: 1, gap: 5, minWidth: 0 }}>
        <div className="row between aic">
          <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>{date}</span>
          <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>{dur}</span>
        </div>
        <span className="h-title" style={{ fontSize: 13 }}>{title}</span>
        {/* mini zone bar */}
        <div className="row" style={{ gap: 2, height: 6 }}>
          {zones.map((z, i) => (
            <div key={i} style={{ flex: z, borderRadius: 2, background: i === zones.length - 1 ? "var(--wf-hr)" : "var(--wf-fill)" }} />
          ))}
        </div>
        <div className="row between aic">
          <div className="row gap-1">
            {tags.map((t, i) => <span key={i} className="pill wf-mono" style={{ fontSize: 8, padding: "1px 6px" }}>{t}</span>)}
          </div>
          <span className="wf-mono" style={{ fontSize: 11, color: "var(--wf-hr)", fontWeight: 600 }}>↑{peak}</span>
        </div>
      </div>
    </div>
  );
}

function Library() {
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={780}>
        <div className="col" style={{ flex: 1, minHeight: 0 }}>
          <div className="col" style={{ padding: "14px 16px 10px", gap: 12 }}>
            <div className="row between aic">
              <span className="h-title" style={{ fontSize: 22 }}>Rolls</span>
              <div className="row gap-2">
                <div className="icon">⌕</div>
                <div className="icon">⚑</div>
              </div>
            </div>

            {/* smart filter bar */}
            <NoteBadge n="1" style={{ top: 50, left: 12 }} />
            <div className="box box--faint row aic gap-2" style={{ padding: "9px 11px" }}>
              <span className="wf-mono" style={{ color: "var(--wf-ink-3)" }}>⌕</span>
              <span className="wf-mono" style={{ fontSize: 11, color: "var(--wf-ink-2)" }}>bad position · above 170 bpm</span>
            </div>

            {/* filter chips */}
            <NoteBadge n="2" style={{ top: 92, right: 14 }} />
            <div className="row gap-2" style={{ flexWrap: "wrap" }}>
              {["All", "This week", "Zone 4+", "⚔ Sub", "⛊ Bad pos"].map((c, i) => (
                <span key={i} className={"pill wf-mono" + (i === 0 ? " pill--on" : "")} style={{ fontSize: 10 }}>{c}</span>
              ))}
            </div>
          </div>

          <div className="divider" />

          {/* list */}
          <NoteBadge n="3" style={{ top: 210, left: 12 }} />
          <div className="col gap-2" style={{ padding: "12px 16px", flex: 1, minHeight: 0 }}>
            <span className="eyebrow">This week · 4 sessions</span>
            <SessionCard date="Tue 21 May" title="Evening Roll" dur="18:42" peak="194" zones={[2,3,2,3,2]} tags={["SCRAMBLE","BAD POS"]} />
            <SessionCard date="Mon 20 May" title="Open Mat" dur="42:10" peak="188" zones={[3,4,3,2,1]} tags={["SUB","SWEEP"]} />
            <SessionCard date="Sat 18 May" title="Comp Class" dur="31:05" peak="191" zones={[2,2,3,4,3]} tags={["SCRAMBLE"]} />
            <SessionCard date="Thu 16 May" title="Drilling" dur="24:30" peak="172" zones={[4,3,2,1,1]} tags={["SWEEP"]} />
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Natural-language filter is the headline feature — query footage by what happened AND by physiology together ('bad position above 170 bpm').",
        "Quick chips for the common cuts: timeframe, hard zones, and tag types.",
        "Each session card packs a lot at a glance: thumbnail, date, duration, a mini zone-distribution bar, the tags applied, and peak HR in the accent. Scannable, not crowded.",
      ]} />
    </div>
  );
}

Object.assign(window, { Library });
