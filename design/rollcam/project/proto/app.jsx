// app.jsx — RollCam prototype router (stack nav + tab bar).
const SCREENS = {
  rolls: Library, stats: Dashboard, timer: TimerSetup, record: LiveRecording,
  post: PostSession, reviewtag: ReviewTag, compare: RoundCompare, export: ExportSuite,
};
const TAB_ROOTS = ["rolls", "stats"];

function RollCamApp() {
  const [hist, setHist] = useState([{ name: "rolls", params: {} }]);
  const top = hist[hist.length - 1];
  const Screen = SCREENS[top.name];

  const nav = (name, params = {}) => setHist((h) => [...h, { name, params }]);
  const back = () => setHist((h) => (h.length > 1 ? h.slice(0, -1) : h));
  const onTab = (id) => setHist([{ name: id, params: {} }]);
  const onRec = () => setHist((h) => [...h, { name: "timer", params: {} }]);

  const isTab = TAB_ROOTS.includes(top.name);
  const fullBleed = top.name === "record";
  const key = top.name + JSON.stringify(top.params) + hist.length;
  const el = <Screen nav={nav} back={back} params={top.params} />;

  return (
    <div className="rc-app" style={{ position: "relative", height: "100%", display: "flex", flexDirection: "column", overflow: "hidden" }}>
      {fullBleed ? (
        <div key={key} style={{ position: "absolute", inset: 0 }}>{el}</div>
      ) : (
        <div key={key} style={{ flex: 1, minHeight: 0, overflowY: "auto" }}>{el}</div>
      )}
      {isTab && <TabBar active={top.name} onTab={onTab} onRec={onRec} />}
    </div>
  );
}

window.RollCamApp = RollCamApp;
