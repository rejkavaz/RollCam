// screens_capture.jsx — Round timer setup + Live recording (portrait/landscape).
function fmt(s) { const m = Math.floor(s / 60); const r = s % 60; return `${m}:${String(r).padStart(2, "0")}`; }

function Stepper({ label, sub, value, onDec, onInc }) {
  return (
    <div className="rc-card" style={{ padding: "14px 16px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
        <span style={{ fontSize: 15, fontWeight: 600 }}>{label}</span>
        <span className="rc-mono" style={{ fontSize: 10.5, color: "var(--rc-text-3)" }}>{sub}</span>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        <button className="rc-tap" onClick={onDec} style={{ width: 34, height: 34, borderRadius: "50%", border: "1px solid var(--rc-line-2)", background: "var(--rc-surface-2)", color: "var(--rc-text)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="minus" size={17} /></button>
        <span className="rc-mono" style={{ fontSize: 21, fontWeight: 600, minWidth: 56, textAlign: "center" }}>{value}</span>
        <button className="rc-tap" onClick={onInc} style={{ width: 34, height: 34, borderRadius: "50%", border: "1px solid var(--rc-line-2)", background: "var(--rc-surface-2)", color: "var(--rc-text)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="plus" size={17} /></button>
      </div>
    </div>
  );
}

function TimerSetup({ nav, back }) {
  const [round, setRound] = useState(300);
  const [rest, setRest] = useState(60);
  const [rounds, setRounds] = useState(3);
  const [voice, setVoice] = useState(true);
  const total = round * rounds + rest * (rounds - 1);
  const blocks = [];
  for (let i = 0; i < rounds; i++) {
    blocks.push({ k: "R" + (i + 1), flex: round });
    if (i < rounds - 1) blocks.push({ k: "rest", flex: rest });
  }
  return (
    <div className="rc-view" style={{ minHeight: "100%", display: "flex", flexDirection: "column" }}>
      <Header eyebrow="Before you record" onBack={back} right={<div style={{ width: 36 }} />} />
      <div style={{ padding: "0 20px 40px", display: "flex", flexDirection: "column", gap: 16, flex: 1 }}>
        <h1 className="rc-h1" style={{ marginTop: -4 }}>Round timer</h1>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <Stepper label="Round length" sub="work interval" value={fmt(round)} onDec={() => setRound((v) => Math.max(60, v - 30))} onInc={() => setRound((v) => v + 30)} />
          <Stepper label="Rest" sub="between rounds" value={fmt(rest)} onDec={() => setRest((v) => Math.max(0, v - 15))} onInc={() => setRest((v) => v + 15)} />
          <Stepper label="Rounds" sub="total" value={rounds} onDec={() => setRounds((v) => Math.max(1, v - 1))} onInc={() => setRounds((v) => v + 1)} />
        </div>

        {/* structure preview */}
        <div className="rc-card" style={{ padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <span className="rc-eyebrow">Session structure</span>
            <span className="rc-mono" style={{ fontSize: 11, color: "var(--rc-text-2)" }}>{fmt(total)} total</span>
          </div>
          <div style={{ display: "flex", gap: 4, alignItems: "stretch" }}>
            {blocks.map((b, i) => (
              <div key={i} style={{ flex: b.flex, display: "flex", flexDirection: "column", gap: 6, minWidth: b.k === "rest" ? 14 : 0 }}>
                <div style={{ height: 26, borderRadius: 6, background: b.k === "rest" ? "transparent" : "var(--rc-hr)",
                  border: b.k === "rest" ? "1px dashed var(--rc-line-2)" : "none", opacity: b.k === "rest" ? 1 : 0.92 }} />
                <span className="rc-mono" style={{ fontSize: 9, textAlign: "center", color: b.k === "rest" ? "var(--rc-text-3)" : "var(--rc-text-2)" }}>{b.k}</span>
              </div>
            ))}
          </div>
        </div>

        {/* voice toggle */}
        <div className="rc-card" style={{ padding: "14px 16px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 3, paddingRight: 12 }}>
            <span style={{ fontSize: 15, fontWeight: 600 }}>Voice countdown</span>
            <span className="rc-mono" style={{ fontSize: 10.5, color: "var(--rc-text-3)" }}>earpiece only · won't hit video mic</span>
          </div>
          <button className="rc-tap" onClick={() => setVoice((v) => !v)} style={{ width: 46, height: 28, borderRadius: 999, border: "none", cursor: "pointer", position: "relative", background: voice ? "var(--rc-hr)" : "var(--rc-surface-3)", transition: "background .2s" }}>
            <span style={{ position: "absolute", top: 3, left: voice ? 21 : 3, width: 22, height: 22, borderRadius: "50%", background: "#fff", transition: "left .2s" }} />
          </button>
        </div>

        {/* device */}
        <div className="rc-card-2" style={{ padding: "12px 14px", display: "flex", alignItems: "center", gap: 11 }}>
          <Icon name="bluetooth" size={17} color="var(--rc-z1)" />
          <span style={{ flex: 1, fontSize: 13 }}>Polar H10</span>
          <span className="rc-mono" style={{ fontSize: 10.5, color: "var(--rc-good)" }}>connected · 84%</span>
        </div>

        <button className="rc-btn rc-btn-hr" style={{ marginTop: "auto" }} onClick={() => nav("record", { round, rest, rounds })}>
          <Icon name="video" size={19} color="#fff" /> Start recording
        </button>
      </div>
    </div>
  );
}

/* ---------------- Live recording ---------------- */
function CameraBG() {
  return (
    <div className="rc-grain rc-vignette" style={{ position: "absolute", inset: 0,
      background: "radial-gradient(130% 100% at 50% 35%, #283041 0%, #11151D 55%, #070A0E 100%)" }}>
      {/* faint figures suggestion */}
      <div style={{ position: "absolute", left: "50%", top: "52%", transform: "translate(-50%,-50%)", width: 150, height: 110, borderRadius: "50%", background: "rgba(255,255,255,.03)", filter: "blur(20px)" }} />
    </div>
  );
}

function HRChip({ bpm, series, compact }) {
  const z = zoneIndex(bpm);
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 11, padding: compact ? "8px 12px" : "10px 14px", borderRadius: 16,
      background: "rgba(10,12,16,.55)", backdropFilter: "blur(14px)", border: "1px solid rgba(255,255,255,.12)" }}>
      <div style={{ width: 9, height: 9, borderRadius: "50%", background: "var(--rc-hr)" }} className="rc-beat" />
      <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 5 }}>
          <span className="rc-mono" style={{ fontSize: compact ? 30 : 38, fontWeight: 600, lineHeight: 1, color: "#fff" }}>{bpm}</span>
          <span className="rc-mono" style={{ fontSize: 11, color: "rgba(255,255,255,.6)" }}>bpm</span>
        </div>
        <span className="rc-mono" style={{ fontSize: 10, fontWeight: 600, color: zoneVar(z) }}>ZONE {z + 1} · {ZONE_NAME[z].toUpperCase()}</span>
      </div>
      <div style={{ marginLeft: 2 }}>
        <HRGraph series={series.slice(-22)} w={compact ? 56 : 70} h={34} min={130} max={198} stroke="#fff" fill={false} grid={false} strokeW={2} />
      </div>
    </div>
  );
}

function RecBtn({ icon, label, big, danger, onClick }) {
  return (
    <button className="rc-tap" onClick={onClick} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 7, background: "none", border: "none", cursor: "pointer" }}>
      <span style={{ width: big ? 66 : 48, height: big ? 66 : 48, borderRadius: "50%",
        border: danger ? "none" : "2px solid rgba(255,255,255,.85)", background: danger ? "var(--rc-hr)" : "rgba(255,255,255,.12)",
        backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center",
        boxShadow: danger ? "0 6px 24px rgba(255,75,58,.45)" : "none" }}>
        {danger ? <span style={{ width: 22, height: 22, borderRadius: 6, background: "#fff" }} /> : <Icon name={icon} size={big ? 26 : 20} color="#fff" />}
      </span>
      <span className="rc-mono" style={{ fontSize: 9, color: "rgba(255,255,255,.85)", letterSpacing: ".08em" }}>{label}</span>
    </button>
  );
}

function LiveRecording({ nav, back, params }) {
  const [orient, setOrient] = useState("portrait");
  const [paused, setPaused] = useState(false);
  const [secs, setSecs] = useState(134);
  const { bpm, series } = useHRStream({ base: 178, running: !paused });
  useEffect(() => {
    if (paused) return;
    const id = setInterval(() => setSecs((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, [paused]);
  const z = zoneIndex(bpm);
  const land = orient === "landscape";

  const topBar = (
    <div style={{ position: "absolute", top: 58, left: 18, right: 18, display: "flex", justifyContent: "space-between", alignItems: "center", zIndex: 3 }}>
      <div style={{ display: "flex", gap: 9 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "7px 12px", borderRadius: 12, background: "rgba(10,12,16,.55)", backdropFilter: "blur(14px)", border: "1px solid rgba(255,255,255,.12)" }}>
          <span className="rc-recdot" style={{ width: 8, height: 8, borderRadius: "50%", background: "var(--rc-hr)" }} />
          <span className="rc-mono" style={{ fontSize: 13, fontWeight: 600, color: "#fff" }}>{paused ? "PAUSED" : fmt(secs)}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", padding: "7px 12px", borderRadius: 12, background: "rgba(10,12,16,.55)", backdropFilter: "blur(14px)", border: "1px solid rgba(255,255,255,.12)" }}>
          <span className="rc-mono" style={{ fontSize: 12, color: "rgba(255,255,255,.85)" }}>ROUND 2 / {params?.rounds || 3}</span>
        </div>
      </div>
      <button className="rc-tap" onClick={back} style={{ width: 34, height: 34, borderRadius: "50%", background: "rgba(10,12,16,.55)", backdropFilter: "blur(14px)", border: "1px solid rgba(255,255,255,.12)", color: "#fff", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="x" size={18} color="#fff" /></button>
    </div>
  );

  const controls = (
    <div style={{ display: "flex", alignItems: "center", gap: 30 }}>
      <RecBtn icon="flip" label="FLIP" />
      <RecBtn big danger label="STOP" onClick={() => nav("post", { id: "s1", fresh: true })} />
      <RecBtn icon={paused ? "play" : "pause"} label={paused ? "RESUME" : "PAUSE"} onClick={() => setPaused((p) => !p)} />
    </div>
  );

  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden", background: "#070A0E" }}>
      <CameraBG />
      {/* letterbox bars for landscape framing */}
      {land && <>
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 150, background: "#000", zIndex: 2 }} />
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 150, background: "#000", zIndex: 2 }} />
      </>}
      {topBar}

      {/* orientation toggle */}
      <div style={{ position: "absolute", top: 108, left: "50%", transform: "translateX(-50%)", zIndex: 4, width: 220 }}>
        <Segmented value={orient} onChange={setOrient} options={[{ v: "portrait", l: "PORTRAIT" }, { v: "landscape", l: "LANDSCAPE" }]} />
      </div>

      {/* zone strip */}
      <div style={{ position: "absolute", left: 18, top: "50%", transform: "translateY(-50%)", display: "flex", flexDirection: "column", gap: 5, zIndex: 3 }}>
        {[4, 3, 2, 1, 0].map((zi) => (
          <div key={zi} className="rc-mono" style={{ fontSize: 9.5, width: 38, textAlign: "center", padding: "4px 0", borderRadius: 6, fontWeight: 600,
            background: zi === z ? zoneVar(zi) : "rgba(10,12,16,.5)", color: zi === z ? "#fff" : "rgba(255,255,255,.45)",
            border: "1px solid " + (zi === z ? zoneVar(zi) : "rgba(255,255,255,.1)"), transition: "all .25s" }}>Z{zi + 1}</div>
        ))}
      </div>

      {/* HR overlay + controls — placement depends on orientation */}
      {!land ? <>
        <div style={{ position: "absolute", top: 168, right: 18, zIndex: 3 }}><HRChip bpm={bpm} series={series} /></div>
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 46, display: "flex", justifyContent: "center", zIndex: 3 }}>{controls}</div>
      </> : <>
        <div style={{ position: "absolute", left: 18, bottom: 168, zIndex: 3 }}><HRChip bpm={bpm} series={series} compact /></div>
        <div style={{ position: "absolute", right: 22, top: "50%", transform: "translateY(-50%)", display: "flex", flexDirection: "column", gap: 22, zIndex: 3 }}>
          <RecBtn big danger label="STOP" onClick={() => nav("post", { id: "s1", fresh: true })} />
          <RecBtn icon={paused ? "play" : "pause"} label={paused ? "RESUME" : "PAUSE"} onClick={() => setPaused((p) => !p)} />
          <RecBtn icon="flip" label="FLIP" />
        </div>
      </>}
    </div>
  );
}

Object.assign(window, { TimerSetup, LiveRecording });
