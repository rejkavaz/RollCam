# App wireframe

_Started 2026-06-04 16:18 UTC_

---

## User

I first want to create a waireframe for a app i want to build,

## Assistant

## Assistant

_[tool: questions_v2]_

Got it — let me make sure I build the right wireframes before diving in. RollCam is a rich concept with a lot of possible screens, so a few quick questions will help me focus.

## User

Questions answered:
- screens: Live camera + HR overlay (recording), Post-session analysis / HR graph, Session library / list of rolls, Long-term athlete dashboard, Round timer setup + round comparison, Tap-to-tag during a roll, Video export suite
- platform: iPhone (portrait mobile app)
- variations: 1 — just one clean take each
- explore: Overall screen structure & layout, Navigation model (tabs, gestures, flow between screens), How HR data is visualized, Where controls live during recording, Information density / how much to show
- fidelity: Cleaner grayscale boxes (more structured)
- branding: Ignore branding — keep it neutral/low-fi
- orientation: Show both
- tags: No — tagging happens in post-review only

## Assistant

_[tool: update_todos]_

_[tool: copy_starter_component]_

_[tool: write_file]_

Let me build the shared wireframe styling and helper components first.

_[tool: write_file]_

Now the shared helper components.

_[tool: write_file]_

Now the recording screens (portrait + landscape).

_[tool: str_replace_edit]_

_[tool: write_file]_

Now the post-session analysis + review/tag screens.

_[tool: write_file]_

Session library + long-term dashboard.

_[tool: write_file]_

_[tool: write_file]_

Round timer + comparison, then the export suite.

_[tool: write_file]_

_[tool: grep]_

Let me check how DCArtboard sizes content before assembling.

_[tool: write_file]_

Card clips to a fixed `width`/`height`, so I'll size each artboard to fit the phone + notes row. Now assembling the canvas.

_[tool: show_html]_

_[tool: show_html]_

_[tool: get_webview_logs]_

Rendering cleanly. Let me check the console and zoom out to see the full canvas.

_[tool: save_screenshot]_

_[tool: save_screenshot]_

_[tool: save_screenshot]_

_[tool: eval_js]_

Let me verify the tall screens (dashboard, post overview, export) aren't clipping their content.

_[tool: update_todos]_

No clipping anywhere. Let me finalize.

_[tool: done]_

Clean. Surfacing to the verifier.

_[tool: fork_verifier_agent]_

RollCam wireframes are ready — **9 screens** laid out on a pannable/zoomable canvas, grouped by flow. Click any frame's label to open it fullscreen (←/→/Esc to move between).

**1 · Capture** — Round timer setup → Recording (portrait) → Recording (landscape)
**2 · Review & analyze** — Post-session overview → Review & tag → Round comparison
**3 · Track progress** — Session library → Athlete dashboard
**4 · Share & export** — Video export suite

Each frame sits next to numbered notes explaining the structural choices (control placement while rolling, HR as the hero overlay, tagging moved to post-review per your call, natural-language library search, etc.). Intentionally low-fi: greyscale boxes with a single red accent reserved for heart-rate data.

A few things I decided so we can react to them:
- **Recording stays minimal** — only flip/stop/pause; no tagging buttons competing with filming.
- **HR overlay is burned into the frame** so exported clips already carry it.
- **One variation each** as requested — easy to fork any frame into A/B options later.

Want me to flesh out any single screen into a clickable hi-fi prototype, add the HRV/readiness or coach-dashboard screens, or branch a screen into 2–3 layout options to compare?

## User

YEs now make a hifi prototype of these screens too

## Assistant

_[tool: invoke_skill]_

Hi-fi prototype it is. This is a real interactive app, so let me pull in the relevant playbooks first.

_[tool: invoke_skill]_

_[tool: invoke_skill]_

_[tool: copy_starter_component]_

_[tool: read_file]_

_[tool: write_file]_

Good — dark device frame in hand. Committing to an aesthetic direction now: **RollCam as a "performance instrument for fighters"** — near-black cinematic UI, a single ember-red heart-rate accent, a cool→hot zone ramp used only for HR, geometric display type (Sora) with mono numerals (JetBrains Mono) for that instrument feel. Restrained, premium motion.

Let me lay down the theme and icon system.

_[tool: write_file]_

Now the icon set (hand-drawn Lucide-style strokes so everything stays crisp and on-brand).

_[tool: write_file]_

## Assistant

_[tool: write_file]_

_[tool: write_file]_

Now session data, then the screens.

_[tool: write_file]_

Progress screens (Library + Dashboard).

_[tool: write_file]_

Capture screens — interactive timer setup + live recording with a wandering HR stream.

_[tool: write_file]_

Review screens (post-session, review/tag with a working scrubber, round comparison).

_[tool: write_file]_

Export suite, then I'll wire the router.

_[tool: write_file]_

Now the router and the HTML shell.

_[tool: write_file]_

_[tool: show_html]_

_[tool: get_webview_logs]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: eval_js]_

_[tool: eval_js]_

The DOM and styles are all correct — the device just overflows the short capture viewport. Let me scale it to fit and re-capture.

_[tool: save_screenshot]_

_[tool: eval_js]_

_[tool: str_replace_edit]_

Found it — the `.rc-view` entrance animation rests at `opacity:0` (fill `both`), and the capture caught it before it played, leaving content invisible. I'll make the resting state visible so it never depends on the animation firing.

_[tool: show_html]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: str_replace_edit]_

The capture environment freezes the animation clock at t=0, so any keyframe starting at `opacity:0` reads as invisible. I'll make the entrance transform-only — content is always visible regardless of the animation clock.

_[tool: show_html]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: multi_screenshot]_

Library looks great. Let me click through the full flow to verify every screen.

_[tool: str_replace_edit]_

Every screen renders and the full navigation flow works — post-session, review/tag with live scrubber, round comparison, export, dashboard, timer, and live recording. Let me add auto-fit so the phone always fits the viewport, then check the console.

_[tool: done]_

_[tool: fork_verifier_agent]_

_[tool: snip]_

The hi-fi RollCam prototype is built and live. Let me tidy context.Done — the **RollCam hi-fi prototype** is ready and live in your tab. It's a fully interactive iOS app, not static mockups.

**Aesthetic direction I committed to:** a "performance instrument for fighters" — near-black cinematic UI, a single ember-red heart-rate accent, a cool→hot zone ramp used only for HR data, geometric display type (Sora) with mono numerals (JetBrains Mono) for that instrument feel.

**All 9 screens, wired into a real flow:**
- **Rolls** (tab) — session library with the natural-language smart query, filter chips, zone-distribution bars, peak HR. Tap any session →
- **Post-session** — HR graph with tag markers, key stats, AI coaching summary, pressure moments. From here: Review & tag · Compare · Build highlight reel.
- **Review & tag** — video player + **draggable HR scrubber** (drag the line, bpm tracks it), one-tap tag buttons that actually drop markers at the playhead.
- **Round comparison** — overlaid round curves with tappable legend toggles + fatigue read-out.
- **Stats** (tab) — Week/All-time toggle, fitness trend, rolling load, personal bests.
- **REC** (center) → **Round timer** (working steppers/toggle) → **Live recording** with a wandering live HR stream, ticking timer, zone strip, and a **Portrait/Landscape** toggle that re-flows the overlay.
- **Share clip** — overlay-style picker that updates the live preview (Cinematic tint, Coach badge, etc.), layout options, on-device face-blur.

Everything's interactive: tab bar, push/back navigation, steppers, toggles, pause/resume, tag-dropping, legend toggles.

A couple of notes:
- The two files are separate — **RollCam Wireframes** (the low-fi canvas) and **RollCam Prototype** (this) — so you can reference both.
- I kept it to exactly the screens we scoped (no invented Home/HRV/coach screens). Say the word and I'll add HRV/readiness, the coach web dashboard, or branch any screen into 2–3 visual directions via Tweaks.

What would you like to refine first?

