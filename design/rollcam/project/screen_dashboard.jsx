// screen_dashboard.jsx — Long-term athlete dashboard.

function BigStat({ k, v, unit, trend, accent }) {
  return (
    <div className="box col" style={{ padding: "11px 12px", gap: 4, flex: 1 }}>
      <span className="wf-mono" style={{ fontSize: 8, letterSpacing: ".08em", color: "var(--wf-ink-3)", textTransform: "uppercase" }}>{k}</span>
      <div className="row aic gap-1" style={{ alignItems: "baseline" }}>
        <span className="wf-mono" style={{ fontSize: 22, fontWeight: 600, color: accent ? "var(--wf-hr)" : "var(--wf-ink)" }}>{v}</span>
        <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>{unit}</span>
      </div>
      {trend && <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>{trend}</span>}
    </div>
  );
}

function Dashboard() {
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={820}>
        <div className="col" style={{ flex: 1, minHeight: 0, padding: "14px 16px 16px", gap: 14, overflow: "hidden" }}>
          <div className="row between aic">
            <div className="col" style={{ gap: 2 }}>
              <span className="eyebrow">Athlete</span>
              <span className="h-title" style={{ fontSize: 20 }}>Your trend</span>
            </div>
            {/* this week / all time toggle */}
            <NoteBadge n="1" style={{ top: 14, right: 14 }} />
            <div className="row" style={{ border: "1px solid var(--wf-line)", borderRadius: 999, overflow: "hidden" }}>
              <span className="wf-mono pill--on" style={{ fontSize: 10, padding: "5px 11px", borderRadius: 0 }}>Week</span>
              <span className="wf-mono" style={{ fontSize: 10, padding: "5px 11px", color: "var(--wf-ink-3)" }}>All time</span>
            </div>
          </div>

          {/* stat grid */}
          <div className="col gap-2">
            <div className="row gap-2">
              <BigStat k="Sessions" v="4" unit="" trend="this week" />
              <BigStat k="Avg peak" v="181" unit="bpm" accent />
            </div>
            <div className="row gap-2">
              <BigStat k="Avg recovery" v="−22" unit="bpm/min" trend="↑ faster" />
              <BigStat k="Zone 4+" v="38" unit="min" />
            </div>
          </div>

          {/* fitness trend line */}
          <NoteBadge n="2" style={{ top: 290, left: 12 }} />
          <div>
            <SecLabel right="lower = fitter">Fitness trend</SecLabel>
            <div className="box" style={{ padding: "10px 8px 6px" }}>
              <HRGraph w={272} h={76} bands={false}
                pts={[.85,.8,.72,.78,.65,.6,.55,.48,.52,.4,.35,.3]} />
              <div className="row between" style={{ marginTop: 4 }}>
                <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>12 wks ago</span>
                <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>now</span>
              </div>
            </div>
          </div>

          {/* rolling load */}
          <NoteBadge n="3" style={{ top: 470, right: 14 }} />
          <div>
            <SecLabel right="training stress">Rolling load</SecLabel>
            <div className="box row aic gap-3" style={{ padding: "10px 12px" }}>
              <Bars w={150} h={42} vals={[.4,.6,.5,.8,.7,.95,.6]} accentIdx={5} />
              <div className="col" style={{ gap: 2 }}>
                <span className="wf-mono" style={{ fontSize: 18, fontWeight: 600, color: "var(--wf-ink)" }}>312</span>
                <span className="wf-mono" style={{ fontSize: 9, color: "var(--wf-ink-3)" }}>load · optimal</span>
              </div>
            </div>
          </div>

          {/* personal bests */}
          <NoteBadge n="4" style={{ bottom: 26, left: 12 }} />
          <div>
            <SecLabel>Personal bests</SecLabel>
            <div className="col gap-2">
              {[["PR peak HR","194 bpm"],["Fastest recovery","−31 bpm/min"],["Longest Zone 5","2:48"]].map((r,i)=>(
                <div key={i} className="box row between aic" style={{ padding: "8px 11px" }}>
                  <span className="wf" style={{ fontSize: 12, color: "var(--wf-ink-2)" }}>{r[0]}</span>
                  <span className="wf-mono" style={{ fontSize: 12, fontWeight: 600, color: "var(--wf-hr)" }}>{r[1]}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Week / All-time toggle flips the whole board between recent snapshot and lifetime records.",
        "Fitness trend is the signature long-term chart: how fast HR drops between rounds over months. Sloping down = getting fitter, and the copy says so plainly.",
        "Rolling load score (weekly bar history + a single number) borrows TSS/HRV concepts from endurance sport — flags optimal vs over-reaching.",
        "Personal bests give the dopamine hits — every record in the HR accent.",
      ]} />
    </div>
  );
}

Object.assign(window, { Dashboard });
