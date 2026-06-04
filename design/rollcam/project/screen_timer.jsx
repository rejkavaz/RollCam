// screen_timer.jsx — Round timer setup + Round comparison.

function Stepper({ label, val, sub }) {
  return (
    <div className="box row between aic" style={{ padding: "10px 12px" }}>
      <div className="col" style={{ gap: 2 }}>
        <span className="wf" style={{ fontSize: 13, color: "var(--wf-ink)", fontWeight: 600 }}>{label}</span>
        {sub && <span className="sub wf-mono" style={{ fontSize: 9 }}>{sub}</span>}
      </div>
      <div className="row aic gap-3">
        <div className="icon icon--circle">−</div>
        <span className="wf-mono" style={{ fontSize: 18, fontWeight: 600, color: "var(--wf-ink)", minWidth: 48, textAlign: "center" }}>{val}</span>
        <div className="icon icon--circle">+</div>
      </div>
    </div>
  );
}

function TimerSetup() {
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={690}>
        <div className="col" style={{ flex: 1, minHeight: 0, padding: "16px 16px", gap: 16 }}>
          <div className="col" style={{ gap: 3 }}>
            <span className="eyebrow">Before you record</span>
            <span className="h-title" style={{ fontSize: 20 }}>Round timer</span>
          </div>

          <NoteBadge n="1" style={{ top: 78, left: 12 }} />
          <div className="col gap-2">
            <Stepper label="Round length" val="5:00" sub="work interval" />
            <Stepper label="Rest" val="1:00" sub="between rounds" />
            <Stepper label="Rounds" val="3" sub="total" />
          </div>

          {/* timeline preview */}
          <NoteBadge n="2" style={{ top: 252, left: 12 }} />
          <div>
            <SecLabel right="18:00 total">Session structure</SecLabel>
            <div className="box row aic" style={{ padding: 10, gap: 4 }}>
              {[["R1",4],["rest",1],["R2",4],["rest",1],["R3",4]].map((s,i)=>(
                <div key={i} className="col center" style={{ flex: s[1], gap: 4 }}>
                  <div style={{ width: "100%", height: 22, borderRadius: 4,
                    background: s[0] === "rest" ? "var(--wf-fill)" : "var(--wf-ink)",
                    border: s[0] === "rest" ? "1px dashed var(--wf-line)" : "none" }} />
                  <span className="wf-mono" style={{ fontSize: 8, color: s[0]==="rest"?"var(--wf-ink-3)":"var(--wf-ink-2)" }}>{s[0]}</span>
                </div>
              ))}
            </div>
          </div>

          {/* earpiece toggle */}
          <NoteBadge n="3" style={{ top: 368, right: 14 }} />
          <div className="box row between aic" style={{ padding: "11px 12px" }}>
            <div className="col" style={{ gap: 2 }}>
              <span className="wf" style={{ fontSize: 13, color: "var(--wf-ink)", fontWeight: 600 }}>Voice countdown</span>
              <span className="sub wf-mono" style={{ fontSize: 9 }}>earpiece only · won't hit video mic</span>
            </div>
            <div style={{ width: 40, height: 23, borderRadius: 999, background: "var(--wf-ink)", position: "relative" }}>
              <div style={{ position: "absolute", top: 2, right: 2, width: 19, height: 19, borderRadius: "50%", background: "#fff" }} />
            </div>
          </div>

          <div className="btn btn--solid row center gap-2" style={{ marginTop: "auto" }}>
            <span style={{ color: "var(--wf-hr)" }}>●</span> Start recording
          </div>
        </div>
      </Phone>

      <Notes items={[
        "Set work / rest / round count once up front. The app auto-segments footage AND the HR stream into rounds from these values.",
        "Live preview of the session shape — work blocks solid, rest blocks dashed — so the plan is obvious before you hit record.",
        "Voice countdown is explicitly earpiece-only so cues don't bleed into the recorded audio. Important detail, called out in the sub-label.",
      ]} />
    </div>
  );
}

function RoundCompare() {
  // three round curves
  const r1 = [.4,.6,.7,.75,.8,.82,.85,.83,.86,.84];
  const r2 = [.45,.6,.68,.7,.72,.74,.72,.7,.71,.69];
  const r3 = [.5,.6,.64,.62,.6,.58,.55,.52,.5,.48];
  return (
    <div className="wf row gap-4">
      <Phone w={320} h={690}>
        <div className="col" style={{ flex: 1, minHeight: 0, padding: "16px 16px", gap: 14 }}>
          <div className="col" style={{ gap: 3 }}>
            <span className="eyebrow">Evening Roll · 3 rounds</span>
            <span className="h-title" style={{ fontSize: 19 }}>Round comparison</span>
          </div>

          {/* overlaid graph */}
          <NoteBadge n="1" style={{ top: 86, left: 12 }} />
          <div className="box" style={{ padding: "12px 10px 8px", position: "relative" }}>
            <div style={{ position: "relative", width: 268, height: 150 }}>
              {[r1,r2,r3].map((p,i)=>(
                <div key={i} style={{ position: "absolute", inset: 0 }}>
                  <HRGraph w={268} h={150} pts={p} bands={i===0}
                    stroke={i===0?"var(--wf-hr)":(i===1?"var(--wf-ink)":"var(--wf-ink-3)")}
                    strokeW={i===0?2.5:2} dashed={i===2} />
                </div>
              ))}
            </div>
            <div className="row between" style={{ marginTop: 4 }}>
              <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>0:00</span>
              <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>5:00</span>
            </div>
          </div>

          {/* legend */}
          <NoteBadge n="2" style={{ top: 300, right: 14 }} />
          <div className="row gap-2">
            {[["R1","var(--wf-hr)","194"],["R2","var(--wf-ink)","188"],["R3","var(--wf-ink-3)","176"]].map((l,i)=>(
              <div key={i} className="box row aic gap-2" style={{ padding: "7px 10px", flex: 1 }}>
                <span style={{ width: 14, height: 0, borderTop: "2px " + (i===2?"dashed":"solid") + " " + l[1] }} />
                <div className="col" style={{ gap: 1 }}>
                  <span className="wf-mono" style={{ fontSize: 10, fontWeight: 600, color: "var(--wf-ink)" }}>{l[0]}</span>
                  <span className="wf-mono" style={{ fontSize: 8, color: "var(--wf-ink-3)" }}>pk {l[2]}</span>
                </div>
              </div>
            ))}
          </div>

          {/* insight */}
          <NoteBadge n="3" style={{ bottom: 60, left: 12 }} />
          <div className="box" style={{ padding: 12, borderLeft: "3px solid var(--wf-hr)", marginTop: "auto" }}>
            <p className="wf" style={{ margin: 0, fontSize: 12, lineHeight: 1.5, color: "var(--wf-ink-2)" }}>
              "Peak HR dropped 194 → 176 across rounds and your curve flattens earlier each round — classic fatigue signature."
            </p>
          </div>
        </div>
      </Phone>

      <Notes items={[
        "All round curves overlaid on one set of axes — the whole point is to SEE the decline round over round, not read three separate charts.",
        "Round 1 in the HR accent, later rounds recede to grey (R3 dashed) so the eye reads the drop as fade-out.",
        "Plain-language fatigue read-out ties the visual to a takeaway. Rest gaps would shade between rounds in the full session view.",
      ]} />
    </div>
  );
}

Object.assign(window, { TimerSetup, RoundCompare });
