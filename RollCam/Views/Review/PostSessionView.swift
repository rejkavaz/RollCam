import SwiftUI

struct PostSessionView: View {
    let session: Session
    var fresh: Bool

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var context

    @State private var showRename = false
    @State private var draftTitle = ""

    private var breakdown: String { SessionAnalytics.breakdown(for: session) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(eyebrow: fresh ? "Saved · just now"
                         : "\(session.dayLabel) · \(session.dateLabel) · \(session.timeLabel)",
                         onBack: { router.pop() }) {
                    Menu {
                        Button { draftTitle = session.title; showRename = true } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button { router.push(.export(id: session.id)) } label: {
                            Label("Export / CSV", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive) { deleteSession() } label: {
                            Label("Delete session", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(RC.text)
                            .frame(width: 36, height: 36)
                            .background(RC.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(session.title).font(RC.display(30, .bold)).foregroundStyle(RC.text)
                    Text("\(session.rounds) rounds · \(session.durationLabel) mat time")
                        .font(RC.mono(12)).foregroundStyle(RC.text3)

                    // HR graph
                    VStack(spacing: 0) {
                        HStack {
                            Eyebrow("Heart rate")
                            Spacer()
                            Text("peak \(session.peak) bpm").font(RC.mono(11)).foregroundStyle(RC.hr)
                        }
                        .padding(.bottom, 14)
                        HRGraph(series: session.series, markers: session.tagged.map(\.pos))
                            .frame(height: 96)
                        HStack {
                            Text("0:00").font(RC.mono(9.5)).foregroundStyle(RC.text3)
                            Spacer()
                            Text(session.durationLabel).font(RC.mono(9.5)).foregroundStyle(RC.text3)
                        }
                        .padding(.top, 10)
                    }
                    .rcCard(16)

                    HStack(spacing: 10) {
                        StatTile(label: "Peak HR", value: "\(session.peak)", unit: "bpm", accent: true)
                        StatTile(label: "Avg HR", value: "\(session.avg)", unit: "bpm")
                    }
                    HStack(spacing: 10) {
                        StatTile(label: "Recovery", value: "\(session.recovery)", unit: "bpm/m")
                        StatTile(label: "Zone 4+", value: "\(session.zone4Minutes)", unit: "min")
                    }

                    // Rule-based session breakdown (replaces the prototype's AI summary).
                    ZStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path.ecg").font(.system(size: 14)).foregroundStyle(RC.hr)
                                Eyebrow("Session breakdown")
                            }
                            Text(breakdown)
                                .font(.system(size: 14))
                                .lineSpacing(4)
                                .foregroundStyle(RC.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Rectangle().fill(RC.hr).frame(width: 3).frame(maxHeight: .infinity)
                    }
                    .rcCard(16)

                    // Pressure moments
                    if !session.pressure.isEmpty {
                        HStack {
                            Eyebrow("Pressure moments")
                            Spacer()
                            Text("\(session.pressure.count) found").font(RC.mono(10)).foregroundStyle(RC.text3)
                        }
                        VStack(spacing: 10) {
                            ForEach(session.pressure) { p in
                                Button { router.push(.reviewTag(id: session.id)) } label: {
                                    HStack(spacing: 12) {
                                        Thumb(size: 46)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(p.label).font(RC.mono(12, .semibold)).foregroundStyle(RC.text)
                                            Text(p.note).font(.system(size: 12)).foregroundStyle(RC.text3)
                                        }
                                        Spacer()
                                        Image(systemName: "play.fill").font(.system(size: 15)).foregroundStyle(RC.text2)
                                    }
                                    .rcCard2(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Button { router.push(.reviewTag(id: session.id)) } label: {
                            Label("Review & tag", systemImage: "tag").font(.system(size: 13.5))
                        }
                        .buttonStyle(RCButtonStyle(kind: .ghost))
                        Button { router.push(.compare(id: session.id)) } label: {
                            Label("Compare", systemImage: "waveform.path.ecg").font(.system(size: 13.5))
                        }
                        .buttonStyle(RCButtonStyle(kind: .ghost))
                    }
                    Button { router.push(.export(id: session.id)) } label: {
                        Label("Build highlight reel", systemImage: "film").font(.system(size: 15))
                    }
                    .buttonStyle(RCButtonStyle(kind: .hr))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .alert("Rename session", isPresented: $showRename) {
            TextField("Title", text: $draftTitle)
            Button("Save") {
                let t = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { session.title = t; try? context.save() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteSession() {
        context.delete(session)
        try? context.save()
        router.popToRoot()
    }
}
