# RollCam

**A native iOS heart-rate-overlay camera for BJJ and grappling — a performance instrument for fighters.**

RollCam films your roll and burns a live heart-rate read-out over it, then turns the recording into something you can actually study: zone distribution, per-round fatigue curves, tagged moments, and a plain-English breakdown of how hard you worked. Everything runs **on-device** — no account, no cloud, no AI, no telemetry. Your sessions, your video, and your HR data never leave the phone unless *you* export them.

> Built with SwiftUI + SwiftData, targeting iOS 17+. The whole app is self-contained: no bundled fonts, no third-party SDKs, no API keys.

---

## Table of contents

- [Why RollCam](#why-rollcam)
- [Features](#features)
- [The "no AI" principle](#the-no-ai-principle)
- [Screens](#screens)
- [Heart-rate hardware](#heart-rate-hardware)
- [Privacy model](#privacy-model)
- [Architecture](#architecture)
- [Project layout](#project-layout)
- [Building locally](#building-locally)
- [CI: building a sideloadable IPA](#ci-building-a-sideloadable-ipa)
- [Installing on your iPhone](#installing-on-your-iphone)
- [Design source](#design-source)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Why RollCam

Heart rate is the most honest signal a grappler has. It doesn't care how the round *felt* — it shows you exactly when you gassed, how fast you recovered between rounds, and which scrambles cost you the most. Most HR apps treat that data as a fitness-tracker afterthought. RollCam treats it as the main event: the number lives *on the footage*, synced frame-to-beat, so you can scrub to the moment your HR spiked and watch what your body was reacting to.

It's deliberately a single-purpose tool. No social feed, no coaching subscription, no machine-learning black box telling you what it thinks you did wrong. Just your roll, your heart, and the math.

## Features

- **Live HR camera** — record with a real-time bpm read-out, current zone, and a rolling mini-graph overlaid on the camera feed. Portrait or landscape framing.
- **Smart round timer** — configurable round / rest / round-count, with a visual session-structure preview and an optional earpiece-only voice countdown that won't bleed into the video mic.
- **Rule-based session breakdown** — a deterministic summary of peak, time-above-threshold, recovery quality and Zone 4+ load. (See [The "no AI" principle](#the-no-ai-principle).)
- **Pressure-moment detection** — automatically flags sharp HR excursions ("you spiked 188→194 here") using a simple, explainable heuristic over the series.
- **Tap-to-tag review** — scrub a draggable playhead across the HR graph (synced to the bpm at that instant) and drop tags: *Sweep, Bad pos, Scramble, Submission, Tap*.
- **Round comparison** — overlay each round's HR curve to see the fatigue signature: peaks dropping and curves flattening earlier round over round.
- **Long-term dashboard** — weekly vs. all-time stats, a fitness-trend line, a rolling-load chart, and personal bests.
- **Export suite** — pick an overlay style (Minimal / Coach / Cinematic / Data-heavy) and layout, with an on-device "blur partners' faces" privacy toggle. Export the HR series as **plain CSV** — your data is yours.
- **Works with no hardware** — a built-in simulated HR source keeps the entire app alive on the Simulator or without a chest strap.

## The "no AI" principle

RollCam contains **zero** machine learning, no model inference, and no network calls for analysis. Every "insight" the app shows is produced by deterministic arithmetic over the recorded HR series, all of which lives in [`SessionAnalytics.swift`](RollCam/Services/SessionAnalytics.swift):

- **Metrics** (peak, average, time-in-zone distribution, Zone 4+ minutes) are direct reductions over the samples.
- **Recovery rate** is the steepest sustained ~1-minute HR drop, expressed as bpm/min.
- **Pressure moments** are local HR maxima where the series rose ≥12 bpm over a short look-back window and crossed an absolute floor.
- **The session "breakdown"** is templated prose assembled from those numbers (e.g. *"HR peaked at 194 bpm around 8:40 (round 2). You held above 160 bpm for 71% of mat time."*).

The upshot: every claim the app makes is traceable to a line of code and a number you can verify. Nothing is hallucinated, nothing phones home.

## Screens

| Screen | What it does |
| --- | --- |
| **Library** | Session list with zone bars, filter chips (This week / Zone 4+ / tag filters), and a saved-query bar. |
| **Dashboard** | Week/all-time toggle, stat tiles, fitness trend, rolling-load bars, personal bests. |
| **Timer setup** | Round/rest/rounds steppers, live session-structure preview, voice-countdown toggle, BLE device row. |
| **Live recording** | Camera (or cinematic fallback), floating HR chip, zone strip, round indicator, flip/pause/stop. Stop saves a `Session`. |
| **Post-session** | Full HR graph with tag markers, stat tiles, the rule-based breakdown, and detected pressure moments. |
| **Review & tag** | Draggable HR scrubber synced to bpm, tap-to-tag buttons, the tagged-moment list. |
| **Round compare** | Overlaid per-round HR curves with legend toggles and a fatigue note. |
| **Export** | Overlay-style picker, layout radios, face-blur toggle, CSV export via the share sheet. |
| **Settings** | HR source (simulated / Bluetooth), max-HR for zone thresholds, voice countdown, privacy info. |

## Heart-rate hardware

RollCam speaks the **standard Bluetooth LE Heart Rate Service** (`0x180D`, measurement characteristic `0x2A37`) — no proprietary SDK, no special entitlement, no pairing code. That means it works with essentially any modern chest strap:

- Polar H10 / H9
- Wahoo TICKR
- Garmin HRM-Pro / HRM-Dual
- …and most other BLE straps

The BLE client lives in [`HeartRateMonitor.swift`](RollCam/Services/HeartRateMonitor.swift). If no strap is connected (or you're on the Simulator), the app falls back to a deterministic **simulated** HR source so every screen stays fully interactive.

## Privacy model

- **All local.** Sessions, video, and HR data are stored on-device via SwiftData. There is no backend.
- **No account, no AI, no telemetry.** The app never makes a network request for analysis.
- **On-device face blur** is applied *before* anything is exported, not after upload.
- **Open data.** Your HR series exports as plain CSV from the share screen.

The Info.plist usage strings ([`project.yml`](project.yml)) spell out exactly why each permission is requested (Bluetooth for the strap, camera/mic to film, photo-library add to save clips).

## Architecture

- **UI:** SwiftUI, dark-only, portrait. A single `NavigationStack` driven by an enum-based `Route`, with sessions referenced by `UUID` and re-fetched per destination so routes stay value types. See [`Router.swift`](RollCam/App/Router.swift) and [`RootView.swift`](RollCam/App/RootView.swift).
- **State:** the Observation framework (`@Observable`, `@Bindable`). App-wide objects (`Router`, `AppSettings`, `HeartRateMonitor`) are injected via `.environment`.
- **Persistence:** SwiftData (`@Model final class Session`). The `ModelContainer` uses a **wipe-and-retry** strategy ([`RollCamApp.swift`](RollCam/App/RollCamApp.swift)): if the on-disk store schema drifts between sideloads, it wipes the store and retries, finally falling back to an in-memory store so the app always renders instead of crashing.
- **Camera:** a thin AVFoundation wrapper ([`CameraController.swift`](RollCam/Services/CameraController.swift)). If the camera can't be configured, it degrades gracefully to a cinematic background — HR, timer and controls still work.
- **Charts:** the HR graph is custom-drawn with `Path` + Catmull-Rom smoothing ([`HRGraph.swift`](RollCam/Components/HRGraph.swift)) so tag markers and the scrubber playhead align exactly with the curve.
- **Type & icons:** the system geometric face for display and the monospaced face for numerals, plus SF Symbols — keeping the build free of bundled binary assets.

## Project layout

```
RollCam/
├─ project.yml                 # XcodeGen spec — generates RollCam.xcodeproj (never committed)
├─ .github/workflows/ipa.yml   # CI: build unsigned .ipa for sideloading
├─ design/                     # original Claude Design handoff bundle (prototype + wireframes)
└─ RollCam/
   ├─ App/                     # @main app, Router, RootView
   ├─ Theme/                   # design tokens (colors, type, button styles)
   ├─ Models/                  # Session @Model, HRZone, sample data
   ├─ Services/                # HR monitor, analytics, camera, speech, CSV export
   ├─ Components/              # HRGraph, ZoneBar, StatTile, chrome, tab bar
   ├─ Views/                   # the nine screens, grouped by feature
   └─ Resources/               # Assets.xcassets (accent color, app icon)
```

The Xcode project is **generated**, not checked in — `project.yml` is the source of truth.

## Building locally

You need a Mac with Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/rejkavaz/RollCam.git
cd RollCam
xcodegen generate          # produces RollCam.xcodeproj
open RollCam.xcodeproj      # build & run on a device or the Simulator
```

On the Simulator the camera and Bluetooth are unavailable, so the app uses the cinematic background and the simulated HR source — every screen still works end-to-end.

> **Windows note:** Swift doesn't compile on Windows. The project is authored on Windows and built entirely by CI; you never touch the `.xcodeproj` locally.

## CI: building a sideloadable IPA

[`.github/workflows/ipa.yml`](.github/workflows/ipa.yml) runs on every push to `master` (and via manual *workflow_dispatch*). On a `macos-15` runner it:

1. Installs XcodeGen and runs `xcodegen generate`.
2. Builds for `generic/platform=iOS`, **unsigned** (`CODE_SIGNING_ALLOWED=NO`), in Release.
3. Strips any residual signature and removes any embedded provisioning profile.
4. Packages `RollCam.app` into `Payload/` and zips it to `RollCam-<sha>-r<run>.ipa`.
5. Uploads the `.ipa` as a **build artifact** (30-day retention) and, on `master`, publishes a **GitHub Release** tagged `ipa-<sha>`.

The build produces an **unsigned** IPA on purpose — you sign it with your own free Apple ID at install time (below). No paid Apple Developer account required.

## Installing on your iPhone

1. Open the [Actions tab](https://github.com/rejkavaz/RollCam/actions) (or [Releases](https://github.com/rejkavaz/RollCam/releases)) and download the latest `RollCam-*.ipa`.
2. Sign and install it with a free Apple ID using either:
   - **[Sideloadly](https://sideloadly.io/)** (Windows/macOS), or
   - **[AltStore](https://altstore.io/)** (with AltServer running).
3. On the phone, trust the developer profile under **Settings → General → VPN & Device Management**, then launch RollCam.

Free-signed apps expire after 7 days — re-install from the latest IPA when that happens. (Pair a chest strap in **Settings → Heart-rate source → Bluetooth** to record real HR.)

## Design source

The `design/` folder contains the original [Claude Design](https://claude.ai) handoff bundle that this app was built from — the HTML prototype, wireframes, the `theme.css` token sheet, and the per-screen `*.jsx` mockups. The Swift implementation ports those screens faithfully, with one deliberate substitution: the prototype's "AI coaching summary" is replaced by the rule-based [`SessionAnalytics`](RollCam/Services/SessionAnalytics.swift) breakdown.

## Roadmap

Ideas from the extended concept that aren't built yet:

- Real timelapse and side-by-side HR-graph video export (the export screen currently configures the overlay and ships CSV).
- Voice-note attachment during review.
- HRV / recovery tracking and readiness scoring (rule-based).
- Optional academy / training-partner sharing — still strictly opt-in and local-first.

## Contributing

Issues and PRs welcome. Because everything is deterministic and local, contributions are easy to reason about — there's no hidden model or server behavior. Keep the core principles intact: **on-device, no AI, no telemetry, open data.**

## License

RollCam is intended to be open-source. If you're reusing it, an MIT license is recommended — add a `LICENSE` file to formalize it.
