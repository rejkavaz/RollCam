import SwiftUI
import SwiftData

struct LiveRecordingView: View {
    let roundLength: Int
    let rest: Int
    let rounds: Int

    @Environment(Router.self) private var router
    @Environment(HeartRateMonitor.self) private var hr
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

    @State private var camera = CameraController()
    @State private var announcer = SpeechAnnouncer()
    @State private var landscape = false
    @State private var paused = false
    @State private var secs = 0
    @State private var capturedSeries: [Double] = []
    // Action markers dropped live while filming. Each captures the elapsed
    // second, label, SF Symbol and the bpm at that instant — converted to
    // TagMarkers on Stop so they flow straight into Review & Tag.
    @State private var liveTags: [LiveTag] = []
    @State private var toast: String?
    @State private var toastID = 0

    // Same vocabulary as Review & Tag so live and post tags stay consistent.
    private let actionTags: [(String, String)] = [
        ("Submission", "figure.martial.arts"),
        ("Sweep", "arrow.triangle.2.circlepath"),
        ("Bad pos", "shield"),
        ("Scramble", "bolt.fill"),
        ("Tap", "checkmark"),
    ]

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var zone: Int { HRZone.index(hr.bpm, max: Double(settings.maxHR)) }

    // Which round/rest the elapsed time falls in, 1-based round number.
    private var currentRound: Int {
        let cycle = roundLength + rest
        guard cycle > 0 else { return 1 }
        return min(rounds, secs / cycle + 1)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x070A0E).ignoresSafeArea()
            if camera.isAvailable {
                CameraPreview(session: camera.session).ignoresSafeArea()
            } else {
                CinematicBackground()
            }

            if landscape {
                Color.black.frame(height: 120).frame(maxHeight: .infinity, alignment: .top).ignoresSafeArea()
                Color.black.frame(height: 120).frame(maxHeight: .infinity, alignment: .bottom).ignoresSafeArea()
            }

            topBar
            orientationToggle
            zoneStrip

            if camera.permissionDenied { permissionBanner }

            if landscape {
                HStack {
                    VStack { Spacer(); HRChip(bpm: hr.bpm, series: hr.series, zone: zone, maxHR: settings.maxHR, compact: true) }
                        .padding(.leading, 18).padding(.bottom, 168)
                    Spacer()
                    VStack(spacing: 22) {
                        stopButton
                        recButton(paused ? "play.fill" : "pause.fill", paused ? "RESUME" : "PAUSE") { paused.toggle() }
                        recButton("arrow.triangle.2.circlepath.camera", "FLIP") { camera.flip() }
                    }
                    .padding(.trailing, 22)
                }
                VStack { Spacer(); tagBar.padding(.bottom, 18) }
            } else {
                VStack {
                    HStack { Spacer(); HRChip(bpm: hr.bpm, series: hr.series, zone: zone, maxHR: settings.maxHR) }
                        .padding(.trailing, 18).padding(.top, 168)
                    Spacer()
                    tagBar.padding(.bottom, 14)
                    controls.padding(.bottom, 46)
                }
            }

            toastOverlay
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            camera.configureIfNeeded(front: settings.frontCamera)
            // Request recording now; CameraController starts it as soon as the
            // session finishes its asynchronous configuration.
            camera.startRecording()
            hr.start(base: 178)
            announcer.enabled = settings.voiceCountdown
        }
        .onDisappear {
            hr.stop()
            camera.stopRecording()
            camera.stop()
        }
        .onReceive(tick) { _ in
            guard !paused else { return }
            secs += 1
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        VStack {
            HStack {
                HStack(spacing: 9) {
                    glassPill {
                        HStack(spacing: 8) {
                            Circle().fill(RC.hr).frame(width: 8, height: 8)
                            Text(paused ? "PAUSED" : Session.clock(secs))
                                .font(RC.mono(13, .semibold)).foregroundStyle(.white)
                        }
                    }
                    glassPill {
                        Text("ROUND \(currentRound) / \(rounds)")
                            .font(RC.mono(12)).foregroundStyle(.white.opacity(0.85))
                    }
                }
                Spacer()
                Button { close() } label: {
                    Image(systemName: "xmark").font(.system(size: 18)).foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.black.opacity(0.55), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 58)
            Spacer()
        }
    }

    // Camera access denied — the roll still records HR + timer, but we nudge
    // the athlete to Settings so they can film the next one.
    private var permissionBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "video.slash.fill").font(.system(size: 18)).foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Camera access off").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    Text("HR + timer still record. Enable the camera to film.")
                        .font(RC.mono(10)).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Settings").font(RC.mono(11, .semibold)).foregroundStyle(.black)
                        .padding(.vertical, 7).padding(.horizontal, 12)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.14), lineWidth: 1))
            .padding(.horizontal, 18)
            .padding(.bottom, 150)
        }
    }

    private var orientationToggle: some View {
        VStack {
            Segmented(options: [
                SegmentOption(value: "portrait", label: "PORTRAIT"),
                SegmentOption(value: "landscape", label: "LANDSCAPE"),
            ], selection: Binding(
                get: { landscape ? "landscape" : "portrait" },
                set: { landscape = $0 == "landscape" }))
            .frame(width: 220)
            .padding(.top, 108)
            Spacer()
        }
    }

    private var zoneStrip: some View {
        HStack {
            VStack(spacing: 5) {
                ForEach([4, 3, 2, 1, 0], id: \.self) { zi in
                    Text("Z\(zi + 1)")
                        .font(RC.mono(9.5, .semibold))
                        .frame(width: 38)
                        .padding(.vertical, 4)
                        .foregroundStyle(zi == zone ? .white : .white.opacity(0.45))
                        .background(zi == zone ? HRZone.color(zi) : Color.black.opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(zi == zone ? HRZone.color(zi) : .white.opacity(0.1), lineWidth: 1))
                        .animation(.easeOut(duration: 0.25), value: zone)
                }
            }
            .padding(.leading, 18)
            Spacer()
        }
    }

    private var controls: some View {
        HStack(spacing: 30) {
            recButton("arrow.triangle.2.circlepath.camera", "FLIP") { camera.flip() }
            stopButton
            recButton(paused ? "play.fill" : "pause.fill", paused ? "RESUME" : "PAUSE") { paused.toggle() }
        }
    }

    // MARK: Live action tagging

    // A row of quick-tap action buttons. Each drops a timestamped marker at the
    // current moment so the athlete can flag sweeps, taps, submissions etc. while
    // they roll — these surface later in Review & Tag.
    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(actionTags, id: \.0) { tag, icon in
                    Button { addLiveTag(tag, symbol: icon) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                            Text(tag.uppercased()).font(RC.mono(10, .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 9).padding(.horizontal, 13)
                        .background(.black.opacity(0.55), in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // A brief confirmation pill that floats near the top when a tag is dropped.
    private var toastOverlay: some View {
        VStack {
            if let toast {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill").font(.system(size: 13)).foregroundStyle(RC.hr)
                    Text(toast).font(RC.mono(12, .semibold)).foregroundStyle(.white)
                }
                .padding(.vertical, 9).padding(.horizontal, 14)
                .background(.black.opacity(0.72), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1))
                .padding(.top, 150)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast)
    }

    private func addLiveTag(_ tag: String, symbol: String) {
        liveTags.append(LiveTag(t: secs, tag: tag, symbol: symbol, bpm: hr.bpm))
        toastID += 1
        let thisToast = toastID
        toast = "\(tag) · \(Session.clock(secs))"
        // Auto-dismiss unless a newer tag has since replaced it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toastID == thisToast { toast = nil }
        }
    }

    private var stopButton: some View {
        Button { stop() } label: {
            VStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 6).fill(.white).frame(width: 22, height: 22)
                    .frame(width: 66, height: 66)
                    .background(RC.hr, in: Circle())
                    .shadow(color: RC.hr.opacity(0.45), radius: 12, y: 6)
                Text("STOP").font(RC.mono(9)).tracking(0.8).foregroundStyle(.white.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
    }

    private func recButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 2))
                Text(label).font(RC.mono(9)).tracking(0.8).foregroundStyle(.white.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
    }

    private func glassPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: Actions

    private func close() {
        hr.stop(); camera.stopRecording(); camera.stop()
        router.pop()
    }

    private func stop() {
        // Snapshot HR before tearing the source down.
        let series = hr.series
        hr.stop()
        let duration = max(secs, 1)
        let maxHR = settings.maxHR
        let sessionID = UUID()

        // Convert the live action taps into post-review markers, positioned along
        // the HR series by their elapsed time.
        let markers: [TagMarker] = liveTags
            .map { lt in
                TagMarker(timeLabel: Session.clock(min(lt.t, duration)),
                          tag: lt.tag, symbol: lt.symbol, bpm: lt.bpm,
                          pos: min(1, Double(lt.t) / Double(duration)))
            }
            .sorted { $0.pos < $1.pos }
        var seen = Set<String>()
        let liveNoteTags = markers.map(\.tag).filter { seen.insert($0).inserted }

        // Wait for the movie file to finish writing, then persist it and save.
        camera.finishRecording { url in
            let savedPath = url.flatMap { Self.persistVideo($0, id: sessionID) }
            let m = SessionAnalytics.metrics(series: series, durationSeconds: duration, maxHR: maxHR)
            let pressure = SessionAnalytics.detectPressure(series: series, durationSeconds: duration, rounds: rounds, maxHR: maxHR)
            let curves = SessionAnalytics.roundCurves(series: series, rounds: rounds)

            let session = Session(
                id: sessionID,
                title: "New Roll",
                date: Date(),
                durationSeconds: duration,
                rounds: rounds,
                peak: m.peak, avg: m.avg, recovery: m.recovery, zone4Minutes: m.zone4Minutes,
                maxHR: maxHR,
                dist: m.dist,
                series: series,
                noteTags: liveNoteTags,
                tagged: markers,
                roundCurves: curves,
                pressure: pressure,
                videoPath: savedPath
            )
            context.insert(session)
            try? context.save()
            router.reset(to: .post(id: session.id, fresh: true))
        }
    }

    /// Move the just-recorded clip out of the purgeable temp dir into
    /// Application Support so it survives for later review.
    ///
    /// Returns the bare *filename* (not an absolute path): the sandbox container
    /// path changes when the app is reinstalled, so Session.videoURL rebuilds
    /// the full URL against the live container at read time. Falls back to an
    /// absolute path only if the move fails.
    private static func persistVideo(_ src: URL, id: UUID) -> String? {
        let fm = FileManager.default
        guard let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                        appropriateFor: nil, create: true) else { return src.path }
        let dir = support.appendingPathComponent("Videos", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = "\(id.uuidString).mov"
        let dst = dir.appendingPathComponent(name)
        try? fm.removeItem(at: dst)
        do {
            try fm.moveItem(at: src, to: dst)
            return name
        } catch {
            return src.path
        }
    }
}

// A marker captured live during recording, before it's positioned along the
// HR series and stored as a TagMarker on Stop.
private struct LiveTag {
    var t: Int          // elapsed seconds when tapped
    var tag: String
    var symbol: String
    var bpm: Int
}

// MARK: - Floating HR chip

struct HRChip: View {
    var bpm: Int
    var series: [Double]
    var zone: Int
    var maxHR: Int
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 11) {
            Circle().fill(RC.hr).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(bpm)").font(RC.mono(compact ? 30 : 38, .semibold)).foregroundStyle(.white)
                    Text("bpm").font(RC.mono(11)).foregroundStyle(.white.opacity(0.6))
                }
                Text("ZONE \(zone + 1) · \(HRZone.name(zone).uppercased())")
                    .font(RC.mono(10, .semibold))
                    .foregroundStyle(HRZone.color(zone))
            }
            HRGraph(series: Array(series.suffix(22)), minY: 130, maxY: 198,
                    stroke: .white, fill: false, grid: false, lineWidth: 2)
                .frame(width: compact ? 56 : 70, height: 34)
        }
        .padding(.horizontal, compact ? 12 : 14).padding(.vertical, compact ? 8 : 10)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }
}
