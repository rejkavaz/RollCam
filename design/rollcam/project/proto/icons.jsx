// icons.jsx — compact stroke icon set (Lucide-style: 24 grid, 1.8 stroke, round caps).
const RC_ICONS = {
  "chevron-left":  "M15 18l-6-6 6-6",
  "chevron-right": "M9 18l6-6-6-6",
  "chevron-down":  "M6 9l6 6 6-6",
  x:        "M6 6l12 12M18 6L6 18",
  check:    "M20 6L9 17l-5-5",
  plus:     "M12 5v14M5 12h14",
  minus:    "M5 12h14",
  heart:    "M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7Z",
  activity: "M22 12h-4l-3 9L9 3l-3 9H2",
  video:    "M16 6H4a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2ZM22 8l-4 4 4 4V8Z",
  camera:   "M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3Z",
  clock:    "M12 7v5l3 2",
  flip:     "M21 2v6h-6M3 12a9 9 0 0 1 15-6.7L21 8M3 22v-6h6M21 12a9 9 0 0 1-15 6.7L3 16",
  list:     "M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01",
  bars:     "M3 3v18h18M18 17V9M13 17V5M8 17v-3",
  share:    "M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13",
  download: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3",
  filter:   "M22 3H2l8 9.46V19l4 2v-8.54L22 3z",
  search:   "M21 21l-4.3-4.3M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z",
  shield:   "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
  zap:      "M13 2L3 14h9l-1 8 10-12h-9l1-8z",
  flag:     "M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22V3",
  tag:      "M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82zM7 7h.01",
  bluetooth:"M6.5 6.5L17.5 17.5 12 23V1l5.5 5.5L6.5 17.5",
  flame:    "M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14-.22-4.05 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 1-3a2.5 2.5 0 0 0 2.5 2.5z",
  trophy:   "M6 9H4.5a2.5 2.5 0 0 1 0-5H6m12 5h1.5a2.5 2.5 0 0 0 0-5H18M6 4h12v6a6 6 0 0 1-12 0V4zM9 20h6M10 22h4M12 16v4",
  "eye-off":"M9.88 9.88a3 3 0 1 0 4.24 4.24M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68M6.61 6.61A13.5 13.5 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61M2 2l20 20",
  mic:      "M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3zM19 10v2a7 7 0 0 1-14 0v-2M12 19v3",
  sparkles: "M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.9L12 3z",
  layers:   "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5",
  film:     "M2 4h20v16H2zM7 4v16M17 4v16M2 9h5M2 15h5M17 9h5M17 15h5",
  captions: "M3 5h18v14H3zM7 14h4M14 14h3M7 10h2M12 10h5",
  "arrow-up":"M12 19V5M5 12l7-7 7 7",
  "arrow-down":"M12 5v14M5 12l7 7 7-7",
  target:   "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12zM12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4z",
  gauge:    "M12 14l4-4M3.34 19a10 10 0 1 1 17.32 0",
  swords:   "M14.5 17.5L3 6V3h3l11.5 11.5M13 19l6-6M16 16l4 4M19 21l2-2M5 14l-2 2M2 19l3 3M9 13l-4 4",
  user:     "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
};
const RC_FILL = new Set(["zap","sparkles"]);

function Icon({ name, size = 20, color = "currentColor", strokeWidth = 1.8, style }) {
  if (name === "dots") {
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill={color} style={style}>
        <circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/>
      </svg>
    );
  }
  if (name === "pause") {
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill={color} style={style}>
        <rect x="6" y="4" width="4" height="16" rx="1.2"/><rect x="14" y="4" width="4" height="16" rx="1.2"/>
      </svg>
    );
  }
  if (name === "play") {
    return <svg width={size} height={size} viewBox="0 0 24 24" fill={color} style={style}><path d="M6 4l14 8-14 8V4Z"/></svg>;
  }
  const d = RC_ICONS[name];
  const filled = RC_FILL.has(name);
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={style}
         fill={filled ? color : "none"} stroke={filled ? "none" : color}
         strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <path d={d} />
    </svg>
  );
}

window.Icon = Icon;
