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

                    ExportPreview(style: style, peak: session.peak)

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
                            Label(session.videoPath == nil ? "No video to render" : "Export clip",
                                  systemImage: "arrow.down.circle").font(.system(size: 15))
                        }
                    }
                    .buttonStyle(RCButtonStyle(kind: .hr))
                    .disabled(rendering || session.videoPath == nil)

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
        guard !rendering, session.videoPath != nil else { return }
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
    var peak: Int

    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0x2A3243), Color(hex: 0x0C0F15)],
                           center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: 260)

            if style == "cinematic" {
                LinearGradient(colors: [RC.z1.opacity(0.20), RC.hr.opacity(0.34)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if style == "minimal" {
                VStack { HStack { Spacer(); Text("\(peak)").font(RC.mono(22, .semibold)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 1).padding(14) }; Spacer() }
            }
            if style == "coach" {
                VStack { HStack { Spacer()
                    HStack(spacing: 8) {
                        Circle().fill(RC.hr).frame(width: 7, height: 7)
                        Text("\(peak)").font(RC.mono(14, .semibold)).foregroundStyle(.white)
                        Text("Z4").font(RC.mono(10)).foregroundStyle(RC.z4)
                    }
                    .padding(.vertical, 6).padding(.horizontal, 11)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
                    .padding(14)
                }; Spacer() }
            }
            if style == "data" {
                VStack { Spacer()
                    HStack(spacing: 10) {
                        Text("\(peak) bpm").font(RC.mono(12, .semibold)).foregroundStyle(RC.hr)
                        Text("ZONE 4").font(RC.mono(10)).foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(.black.opacity(0.6))
                }
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
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
