// screens_progress.jsx — Library + Dashboard.

function Thumb({ size = 64, dur }) {
  return (
    <div className="rc-grain" style={{ position: "relative", width: size, height: size, borderRadius: 12, overflow: "hidden", flex: "0 0 auto",
      background: "radial-gradient(120% 120% at 30% 20%, #2A3140, #0E1116)", border: "1px solid var(--rc-line)" }}>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ width: 22, height: 22, borderRadius: "50%", background: "rgba(255,255,255,.16)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Icon name="play" size={11} color="#fff" />
        </div>
      </div>
      {dur && <span className="rc-mono" style={{ position: "absolute", bottom: 4, right: 4, fontSize: 8.5, color: "#fff", background: "rgba(0,0,0,.5)", padding: "1px 4px", borderRadius: 4 }}>{dur}</span>}
    </div>
  );
}

function SessionCard({ s, onClick }) {
  return (
    <div className="rc-card rc-tap" onClick={onClick} style={{ padding: 14, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "flex", gap: 13, alignItems: "center" }}>
        <Thumb dur={s.duration} />
        <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 5 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span className="rc-eyebrow">{s.day} · {s.date}</span>
            <div style={{ display: "flex", alignItems: "center", gap: 4, color: "var(--rc-hr)" }}>
              <Icon name="arrow-up" size={13} color="var(--rc-hr)" />
              <span className="rc-mono" style={{ fontSize: 13, fontWeight: 600 }}>{s.peak}</span>
            </div>
          </div>
          <span className="rc-h3">{s.title}</span>
          <span className="rc-mono" style={{ fontSize: 11, color: "var(--rc-text-3)" }}>{s.rounds} rounds · avg {s.avg} bpm</span>
        </div>
      </div>
      <ZoneBar dist={s.dist} h={7} />
      <div style={{ display: "flex", gap: 6 }}>
        {s.tags.map((t, i) => (
          <span key={i} className="rc-mono" style={{ fontSize: 10, color: "var(--rc-text-2)", background: "var(--rc-surface-2)", border: "1px solid var(--rc-line)", padding: "3px 9px", borderRadius: 999 }}>{t}</span>
        ))}
      </div>
    </div>
  );
}

function Library({ nav }) {
  const [filter, setFilter] = useState("All");
  const chips = ["All", "This week", "Zone 4+", "Submission", "Bad pos"];
  return (
    <div className="rc-view">
      <Header large eyebrow="87 rolls logged · 14h 32m" title="Rolls"
        right={<><IconBtn name="search" /><IconBtn name="filter" /></>} />
      <div style={{ padding: "0 20px 36px", display: "flex", flexDirection: "column", gap: 16 }}>
        {/* smart query */}
        <div className="rc-card-2 rc-tap" style={{ padding: "13px 14px", display: "flex", alignItems: "center", gap: 11 }}>
          <Icon name="search" size={17} color="var(--rc-text-3)" />
          <span style={{ flex: 1, fontSize: 13, color: "var(--rc-text-2)" }}>
            <span className="rc-mono" style={{ color: "var(--rc-text)" }}>bad position</span> · above <span className="rc-mono" style={{ color: "var(--rc-hr)" }}>170 bpm</span>
          </span>
          <Icon name="sparkles" size={15} color="var(--rc-text-3)" />
        </div>
        {/* chips */}
        <div style={{ display: "flex", gap: 8, overflowX: "auto", margin: "0 -20px", padding: "0 20px" }}>
          {chips.map((c) => (
            <span key={c} className={"rc-pill" + (filter === c ? " on" : "")} onClick={() => setFilter(c)}>{c}</span>
          ))}
        </div>
        <span className="rc-eyebrow" style={{ marginTop: 2 }}>This week · 4 sessions</span>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {RC_SESSIONS.map((s) => <SessionCard key={s.id} s={s} onClick={() => nav("post", { id: s.id })} />)}
        </div>
      </div>
    </div>
  );
}

function LoadBars({ vals }) {
  const max = Math.max(...vals);
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 46 }}>
      {vals.map((v, i) => (
        <div key={i} style={{ flex: 1, height: `${(v / max) * 100}%`, borderRadius: 4,
          background: i === vals.length - 2 ? "var(--rc-hr)" : "var(--rc-surface-3)" }} />
      ))}
    </div>
  );
}

function Dashboard({ nav }) {
  const [range, setRange] = useState("week");
  const w = RC_WEEK;
  return (
    <div className="rc-view">
      <Header large eyebrow="Athlete" title="Your trend" />
      <div style={{ padding: "0 20px 36px", display: "flex", flexDirection: "column", gap: 16 }}>
        <Segmented value={range} onChange={setRange} options={[{ v: "week", l: "THIS WEEK" }, { v: "all", l: "ALL TIME" }]} />

        <div style={{ display: "flex", gap: 10 }}>
          <StatTile label="Sessions" value={range === "week" ? "4" : "87"} sub={range === "week" ? "this week" : "all time"} />
          <StatTile label="Avg peak" value={w.avgPeak} unit="bpm" accent />
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <StatTile label="Avg recovery" value="−22" unit="bpm/m" trend="↑ faster" />
          <StatTile label="Zone 4+" value={w.zone4} unit="min" />
        </div>

        {/* fitness trend */}
        <div className="rc-card" style={{ padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <span className="rc-eyebrow">Fitness trend</span>
            <span className="rc-mono" style={{ fontSize: 10, color: "var(--rc-good)" }}>↓ lower = fitter</span>
          </div>
          <HRGraph series={w.trend} w={300} h={84} min={85} max={160} stroke="var(--rc-good)" area="var(--rc-good)" grid={false} animate />
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8 }}>
            <span className="rc-mono" style={{ fontSize: 9.5, color: "var(--rc-text-3)" }}>12 wks ago</span>
            <span className="rc-mono" style={{ fontSize: 9.5, color: "var(--rc-text-3)" }}>now</span>
          </div>
        </div>

        {/* rolling load */}
        <div className="rc-card" style={{ padding: 16, display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ flex: 1 }}>
            <span className="rc-eyebrow">Rolling load</span>
            <div style={{ marginTop: 12 }}><LoadBars vals={w.load} /></div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 4 }}>
            <span className="rc-mono" style={{ fontSize: 28, fontWeight: 600 }}>{w.loadScore}</span>
            <span className="rc-pill" style={{ padding: "3px 10px", fontSize: 10.5, color: "var(--rc-good)", borderColor: "rgba(56,211,159,.3)" }}>Optimal</span>
          </div>
        </div>

        {/* personal bests */}
        <span className="rc-eyebrow" style={{ marginTop: 2 }}>Personal bests</span>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {RC_BESTS.map((b, i) => (
            <div key={i} className="rc-card-2" style={{ padding: "13px 14px", display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: "var(--rc-hr-dim)", display: "flex", alignItems: "center", justifyContent: "center", flex: "0 0 auto" }}>
                <Icon name={b.icon} size={17} color="var(--rc-hr)" />
              </div>
              <span style={{ flex: 1, fontSize: 14, color: "var(--rc-text-2)" }}>{b.k}</span>
              <span className="rc-mono" style={{ fontSize: 14, fontWeight: 600, color: "var(--rc-hr)" }}>{b.v}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Library, Dashboard, SessionCard, Thumb });
