import SwiftUI

struct ExportView: View {
    let session: Session

    @Environment(Router.self) private var router
    @Environment(AppSettings.self) private var settings

    @State private var style = "cinematic"
    @State private var layout = "side"
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var rendering = false
    @State private var renderProgress = 0.0
    @State private var errorMessage: String?

    private let styles: [(id: String, name: String, desc: String)] = [
        ("minimal", "Minimal", "HR number only"),
        ("coach", "Coach", "badge + zone"),
        ("cinematic", "Cinematic", "tint shifts with HR"),
        ("data", "Data-heavy", "caption + graph"),
    ]
    private let layouts: [(id: String, name: String, desc: String, icon: String)] = [
        ("side", "Side-by-side", "video + scrolling HR graph", "square.split.2x1"),
        ("lapse", "Timelapse", "5 min → 30s, graph racing", "film"),
        ("cap", "Subtitle caption", "HR + zone bottom bar", "captions.bubble"),
    ]

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RCHeader(eyebrow: "Export · highlight · 0:30", onBack: { router.pop() }) {
                    IconButton(systemName: "square.and.arrow.up")
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("Share clip").font(RC.display(30, .bold)).foregroundStyle(RC.text)

                    ExportPreview(style: style, session: session)

                    // Overlay style picker
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Overlay style")
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(styles, id: \.id) { s in
                                let on = style == s.id
                                Button { style = s.id } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(s.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(RC.text)
                                            Spacer()
                                            if on { Image(systemName: "checkmark").font(.system(size: 14)).foregroundStyle(RC.hr) }
                                        }
                                        Text(s.desc).font(RC.mono(10)).foregroundStyle(RC.text3)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(on ? RC.hrDim : RC.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? RC.hr : RC.line, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Layout radios
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Layout")
                        VStack(spacing: 10) {
                            ForEach(layouts, id: \.id) { l in
                                let on = layout == l.id
                                Button { layout = l.id } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: l.icon).font(.system(size: 19))
                                            .foregroundStyle(on ? RC.text : RC.text3)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(l.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(RC.text)
                                            Text(l.desc).font(RC.mono(10)).foregroundStyle(RC.text3)
                                        }
                                        Spacer()
                                        ZStack {
                                            Circle().strokeBorder(on ? RC.hr : RC.line2, lineWidth: 2)
                                            if on { Circle().fill(RC.hr).frame(width: 12, height: 12)
                                                .overlay(Circle().fill(.white).frame(width: 7, height: 7)) }
                                        }
                                        .frame(width: 20, height: 20)
                                    }
                                    .padding(.vertical, 12).padding(.horizontal, 14)
                                    .background(RC.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? RC.line2 : RC.line, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Privacy: blur faces (on-device toggle)
                    HStack(spacing: 12) {
                        Image(systemName: "eye.slash").font(.system(size: 17)).foregroundStyle(RC.text2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Blur partners' faces").font(.system(size: 14, weight: .semibold)).foregroundStyle(RC.text)
                            Text("on-device · before anything leaves the phone")
                                .font(RC.mono(10)).foregroundStyle(RC.text3)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.blurFaces).labelsHidden().tint(RC.good)
                    }
                    .rcCard2(14)

                    Button { exportVideo() } label: {
                        if rendering {
                            Label("Rendering · \(Int(renderProgress * 100))%", systemImage: "gearshape.2")
                                .font(.system(size: 15))
                        } else {
                            Label(session.videoURL == nil ? "No video to render" : "Export clip",
                                  systemImage: "arrow.down.circle").font(.system(size: 15))
                        }
                    }
                    .buttonStyle(RCButtonStyle(kind: .hr))
                    .disabled(rendering || session.videoURL == nil)

                    HStack(spacing: 8) {
                        Spacer()
                        ForEach(["Save", "Instagram", "WhatsApp", "CSV"], id: \.self) { d in
                            Button { if d == "CSV" { exportCSV() } else { exportVideo() } } label: {
                                Text(d).font(RC.mono(11)).foregroundStyle(RC.text2)
                                    .padding(.vertical, 7).padding(.horizontal, 13)
                                    .overlay(Capsule().strokeBorder(RC.line2, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showShare) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
        .alert("Export failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func exportCSV() {
        if let url = ExportService.writeCSV(for: session) {
            shareURL = url
            showShare = true
        }
    }

    private func exportVideo() {
        guard !rendering, session.videoURL != nil else { return }
        rendering = true
        renderProgress = 0
        ExportService.renderClip(for: session, style: style, blurFaces: settings.blurFaces) { p in
            renderProgress = p
        } completion: { result in
            rendering = false
            switch result {
            case .success(let url):
                shareURL = url
                showShare = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Overlay style preview

struct ExportPreview: View {
    var style: String
    var session: Session

    private var peak: Int { session.peak }
    private var avg: Int { session.avg }
    private var zi: Int { HRZone.index(session.peak, max: Double(session.maxHR)) }
    private var zClr: Color { HRZone.color(zi) }

    // Real series when we have one; otherwise a gentle wave just for the preview.
    private var previewSeries: [Double] {
        if session.series.count > 1 { return session.series }
        var wave: [Double] = []
        for i in 0..<44 {
            let t = Double(i)
            let v: Double = 150.0 + 26.0 * sin(t / 5.0) + t * 0.5
            wave.append(v)
        }
        return wave
    }
    private var lo: Double { (previewSeries.min() ?? 120) - 6 }
    private var hi: Double { (previewSeries.max() ?? 190) + 6 }

    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0x2A3243), Color(hex: 0x0C0F15)],
                           center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: 260)

            switch style {
            case "minimal":  minimalOverlay
            case "coach":    coachOverlay
            case "data":     dataOverlay
            default:         cinematicOverlay
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
    }

    private var ribbon: some View {
        HRGraph(series: previewSeries, minY: lo, maxY: hi, stroke: zClr, area: zClr,
                fill: true, grid: false, lineWidth: 2, padTop: 6, padBot: 0)
    }

    // Top-right frosted chip with the peak number only.
    private var minimalOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 1) {
                    Text("\(peak)").font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("♥ LIVE BPM").font(RC.mono(8, .semibold)).tracking(1).foregroundStyle(zClr)
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            }
            Spacer()
        }
        .padding(14)
    }

    // Top-right badge: heart dot + peak + zone pill + avg line.
    private var coachOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(zClr).frame(width: 7, height: 7).shadow(color: zClr, radius: 4)
                        Text("\(peak)").font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Z\(zi + 1)").font(RC.mono(9, .heavy)).foregroundStyle(.white)
                            .padding(.vertical, 2).padding(.horizontal, 7)
                            .background(zClr, in: Capsule())
                    }
                    Text("AVG \(avg) · \(HRZone.name(zi).uppercased())")
                        .font(RC.mono(8, .medium)).foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            }
            Spacer()
        }
        .padding(14)
    }

    // Full-frame: zone tint + bottom scrim + lockup above a glowing HR ribbon.
    private var cinematicOverlay: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [zClr.opacity(0.20), .clear],
                           startPoint: .bottomLeading, endPoint: .center)
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text("LIVE HEART RATE").font(RC.mono(7.5, .semibold)).tracking(1.2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(peak)").font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("PEAK \(peak) · AVG \(avg) BPM").font(RC.mono(8, .semibold)).foregroundStyle(zClr)
                }
                .padding(.leading, 14).padding(.bottom, 4)
                ribbon.frame(height: 30)
            }
        }
    }

    // Bottom frosted data bar: stats column + zone pill + graph + time axis.
    private var dataOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("LIVE HR").font(RC.mono(7, .semibold)).foregroundStyle(.white.opacity(0.55))
                    Text("\(peak)").font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("PEAK \(peak) · AVG \(avg) BPM").font(RC.mono(8, .medium)).foregroundStyle(zClr)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Z\(zi + 1) · \(HRZone.name(zi).uppercased())")
                            .font(RC.mono(7.5, .bold)).foregroundStyle(.white)
                            .padding(.vertical, 2).padding(.horizontal, 7)
                            .background(zClr, in: Capsule())
                        Spacer()
                    }
                    ribbon.frame(height: 28)
                    HStack {
                        Text("0:00").font(RC.mono(7)).foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text(session.durationLabel).font(RC.mono(7)).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.62))
            .overlay(alignment: .top) { Rectangle().fill(zClr.opacity(0.85)).frame(height: 1.5) }
        }
    }
}

// MARK: - UIKit share sheet bridge

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
