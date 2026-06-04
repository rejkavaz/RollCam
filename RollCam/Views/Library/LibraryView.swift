import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(Router.self) private var router
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var filter = "All"

    private let chips = ["All", "This week", "Zone 4+", "Submission", "Bad pos"]

    private var filtered: [Session] {
        switch filter {
        case "This week":
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
            return sessions.filter { $0.date >= cutoff }
        case "Zone 4+":
            return sessions.filter { $0.zone4Minutes >= 35 }
        case "Submission", "Bad pos":
            return sessions.filter { $0.noteTags.contains(filter) }
        default:
            return sessions
        }
    }

    private var totalLabel: String {
        let secs = sessions.reduce(0) { $0 + $1.durationSeconds }
        let h = secs / 3600, m = (secs % 3600) / 60
        return "\(sessions.count) rolls logged · \(h)h \(m)m"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(title: "Rolls", eyebrow: totalLabel, large: true)

                VStack(alignment: .leading, spacing: 16) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(chips, id: \.self) { c in
                                    Chip(label: c, selected: filter == c) { filter = c }
                                }
                            }
                        }
                        .scrollClipDisabled()

                        Eyebrow("\(filtered.count) session\(filtered.count == 1 ? "" : "s")")

                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { s in
                                SessionCard(s: s) {
                                    router.push(.post(id: s.id, fresh: false))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(RC.hr)
            Text("No rolls yet")
                .font(RC.display(20, .semibold))
                .foregroundStyle(RC.text)
            Text("Tap the record button to film your first roll with a live heart-rate overlay. Your sessions show up here.")
                .font(.system(size: 13))
                .foregroundStyle(RC.text3)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            Button { router.push(.timer) } label: {
                Label("Record a roll", systemImage: "video.fill")
            }
            .buttonStyle(RCButtonStyle(kind: .hr))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Session card

struct SessionCard: View {
    let s: Session
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 13) {
                    Thumb(dur: s.durationLabel)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Eyebrow("\(s.dayLabel) · \(s.dateLabel)")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up").font(.system(size: 12, weight: .semibold))
                                Text("\(s.peak)").font(RC.mono(13, .semibold))
                            }
                            .foregroundStyle(RC.hr)
                        }
                        Text(s.title)
                            .font(RC.display(17, .semibold))
                            .foregroundStyle(RC.text)
                        Text("\(s.rounds) rounds · avg \(s.avg) bpm")
                            .font(RC.mono(11))
                            .foregroundStyle(RC.text3)
                    }
                }
                ZoneBar(dist: s.dist, height: 7)
                HStack(spacing: 6) {
                    ForEach(s.noteTags, id: \.self) { t in
                        Text(t)
                            .font(RC.mono(10))
                            .foregroundStyle(RC.text2)
                            .padding(.vertical, 3).padding(.horizontal, 9)
                            .background(RC.surface2, in: Capsule())
                            .overlay(Capsule().strokeBorder(RC.line, lineWidth: 1))
                    }
                    Spacer(minLength: 0)
                }
            }
            .rcCard(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Video thumbnail placeholder

struct Thumb: View {
    var size: CGFloat = 64
    var dur: String? = nil

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A3140), Color(hex: 0x0E1116)],
                center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: size)
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: size * 0.34, height: size * 0.34)
                .overlay(Image(systemName: "play.fill").font(.system(size: size * 0.17)).foregroundStyle(.white))
            if let dur {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(dur)
                            .font(RC.mono(8.5))
                            .foregroundStyle(.white)
                            .padding(.vertical, 1).padding(.horizontal, 4)
                            .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                            .padding(4)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
    }
}
