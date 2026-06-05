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
            recordingDiagnostic

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
            } else {
                VStack {
                    HStack { Spacer(); HRChip(bpm: hr.bpm, series: hr.series, zone: zone, maxHR: settings.maxHR) }
                        .padding(.trailing, 18).padding(.top, 168)
                    Spacer()
                    controls.padding(.bottom, 46)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            camera.configureIfNeeded()
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

    // TEMPORARY DIAGNOSTIC — live camera/recording state during a roll.
    // Remove once the video issue is confirmed fixed on-device.
    private var recordingDiagnostic: some View {
        VStack {
            Spacer()
            Text("avail: \(camera.isAvailable ? "Y" : "N")  rec: \(camera.isRecording ? "Y" : "N")  denied: \(camera.permissionDenied ? "Y" : "N")  preview: \(camera.isAvailable ? "cam" : "fallback")")
                .font(RC.mono(10, .semibold)).foregroundStyle(.white)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(.black.opacity(0.7), in: Capsule())
                .padding(.bottom, 116)
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
                noteTags: [],
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
