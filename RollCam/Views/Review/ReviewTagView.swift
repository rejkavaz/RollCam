import SwiftUI

struct ReviewTagView: View {
    let session: Session

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var context

    @State private var ph: Double = 0.46
    @State private var video = VideoController()
    @State private var moveCategory: MoveCategory = .outcomes

    private var n: Int { max(1, session.series.count) }
    private var bpmAt: Int {
        // A session can have no HR samples (e.g. Bluetooth selected but no strap
        // paired). Guard the subscript so review never traps on an empty series.
        guard !session.series.isEmpty else { return 0 }
        let idx = min(n - 1, max(0, Int((ph * Double(n - 1)).rounded())))
        return Int(session.series[idx].rounded())
    }
    private var timeAt: String { Session.clock(Int(ph * Double(session.durationSeconds))) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                player
                VStack(alignment: .leading, spacing: 18) {
                    scrubber
                    tagDrop
                    taggedList
                    Button {} label: {
                        Label("Hold to add 30s voice note", systemImage: "mic")
                    }
                    .buttonStyle(RCButtonStyle(kind: .soft))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(RC.line, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .onAppear { video.load(url: session.videoURL) }
        .onDisappear { video.pause() }
        .onChange(of: video.progress) { _, newValue in
            if video.isPlaying { ph = newValue }
        }
    }

    // MARK: Player

    private var player: some View {
        ZStack {
            if video.hasVideo {
                VideoLayerView(player: video.player).ignoresSafeArea()
            } else {
                RadialGradient(colors: [Color(hex: 0x283041), Color(hex: 0x0B0E13)],
                               center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 300)
            }
            Button { video.togglePlay() } label: {
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: video.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22)).foregroundStyle(.white))
                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .opacity(video.hasVideo ? 1 : 0.5)
            .disabled(!video.hasVideo)

            VStack {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20)).foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.55), in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.top, 56).padding(.leading, 18)
                Spacer()
                HStack {
                    (Text(timeAt).foregroundStyle(.white)
                     + Text(" / \(session.durationLabel)").foregroundStyle(.white.opacity(0.5)))
                        .font(RC.mono(12))
                    Spacer()
                    Text("\(bpmAt) bpm").font(RC.mono(12, .semibold)).foregroundStyle(RC.hr)
                }
                .padding(.bottom, 14).padding(.horizontal, 18)
            }
        }
        .frame(height: 240)
        .clipped()
    }

    // MARK: Scrubber

    private var scrubber: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Eyebrow("Scrub · HR synced")
                Spacer()
                Text("drag the line").font(RC.mono(10)).foregroundStyle(RC.text3)
            }
            GeometryReader { geo in
                HRGraph(series: session.series, grid: false,
                        markers: session.tagged.map(\.pos), playhead: ph)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                        video.pause()
                        ph = min(1, max(0, v.location.x / geo.size.width))
                        video.seek(toFraction: ph)
                    })
            }
            .frame(height: 78)
        }
        .rcCard(14)
    }

    private var tagDrop: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow("Tap to tag")
                Spacer()
                Text("drops at \(timeAt)").font(RC.mono(10)).foregroundStyle(RC.text3)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoveCategory.allCases) { cat in
                        Chip(label: cat.label, selected: moveCategory == cat) {
                            moveCategory = cat
                        }
                    }
                }
            }
            .scrollClipDisabled()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)],
                      alignment: .leading, spacing: 8) {
                ForEach(moveCategory.moves) { m in
                    Button { addTag(m.name, symbol: m.symbol) } label: {
                        HStack(spacing: 7) {
                            Image(systemName: m.symbol).font(.system(size: 14)).foregroundStyle(RC.text2)
                            Text(m.name).font(.system(size: 12)).foregroundStyle(RC.text)
                                .lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10).padding(.horizontal, 11)
                        .background(RC.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var taggedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Tagged moments · \(session.tagged.count)")
            VStack(spacing: 8) {
                ForEach(session.tagged) { t in
                    HStack(spacing: 11) {
                        Image(systemName: t.symbol).font(.system(size: 16)).foregroundStyle(RC.text2)
                        Text(t.timeLabel).font(RC.mono(12)).foregroundStyle(RC.text).frame(width: 44, alignment: .leading)
                        Text(t.tag).font(.system(size: 13)).foregroundStyle(RC.text)
                        Spacer()
                        Text("\(t.bpm) bpm").font(RC.mono(12, .semibold)).foregroundStyle(RC.hr)
                    }
                    .rcCard2(10)
                }
            }
        }
    }

    private func addTag(_ tag: String, symbol: String) {
        let marker = TagMarker(timeLabel: timeAt, tag: tag, symbol: symbol, bpm: bpmAt, pos: ph)
        session.tagged.append(marker)
        session.tagged.sort { $0.pos < $1.pos }
        // Keep the session's note tags in sync so Library filters/chips match.
        var seen = Set<String>()
        session.noteTags = session.tagged.map(\.tag).filter { seen.insert($0).inserted }
        try? context.save()
    }
}
