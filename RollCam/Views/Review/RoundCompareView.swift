import SwiftUI

struct RoundCompareView: View {
    let session: Session

    @Environment(Router.self) private var router
    @State private var hidden: Set<String> = []

    private var curves: [RoundCurve] { session.roundCurves }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(eyebrow: "\(session.title) · \(session.rounds) rounds",
                         onBack: { router.pop() })

                VStack(alignment: .leading, spacing: 16) {
                    Text("Round comparison").font(RC.display(30, .bold)).foregroundStyle(RC.text)

                    if curves.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg").font(.system(size: 28)).foregroundStyle(RC.text3)
                            Text("No per-round curves captured for this session.")
                                .font(.system(size: 13)).foregroundStyle(RC.text3)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .rcCard(20)
                    } else {
                        // Overlaid graph
                        VStack(spacing: 0) {
                            HStack {
                                Eyebrow("HR per round · overlaid")
                                Spacer()
                                Text("0:00 – \(Session.clock(session.durationSeconds / max(1, session.rounds)))")
                                    .font(RC.mono(10)).foregroundStyle(RC.text3)
                            }
                            .padding(.bottom, 12)
                            ZStack {
                                ForEach(Array(curves.enumerated()), id: \.element.id) { i, c in
                                    if !hidden.contains(c.label) {
                                        HRGraph(series: c.series, minY: 140, maxY: 198,
                                                stroke: Color(hex: c.colorHex), area: RC.hr,
                                                fill: i == 0, grid: i == 0,
                                                lineWidth: i == 0 ? 2.6 : 2)
                                    }
                                }
                            }
                            .frame(height: 158)
                        }
                        .rcCard(16)

                        // Legend toggles
                        HStack(spacing: 10) {
                            ForEach(curves) { c in
                                let off = hidden.contains(c.label)
                                Button {
                                    if off { hidden.remove(c.label) } else { hidden.insert(c.label) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack(spacing: 7) {
                                            RoundedRectangle(cornerRadius: 2).fill(Color(hex: c.colorHex))
                                                .frame(width: 16, height: 3)
                                            Text(c.label).font(RC.mono(12, .semibold)).foregroundStyle(RC.text)
                                        }
                                        Text("peak \(c.peak)").font(RC.mono(10)).foregroundStyle(RC.text3)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 11).padding(.horizontal, 10)
                                    .background(RC.surface2, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
                                    .opacity(off ? 0.4 : 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Fatigue insight
                        ZStack(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "waveform.path.ecg").font(.system(size: 14)).foregroundStyle(RC.hr)
                                    Eyebrow("Fatigue signature")
                                }
                                Text(SessionAnalytics.fatigueNote(curves: curves))
                                    .font(.system(size: 14)).lineSpacing(4).foregroundStyle(RC.text)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Rectangle().fill(RC.hr).frame(width: 3).frame(maxHeight: .infinity)
                        }
                        .rcCard(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }
}
