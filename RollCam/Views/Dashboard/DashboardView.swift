import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(Router.self) private var router
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var range = "week"

    private var weekSessions: [Session] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return sessions.filter { $0.date >= cutoff }
    }
    private var scope: [Session] { range == "week" ? weekSessions : sessions }

    private var avgPeak: Int {
        guard !scope.isEmpty else { return 0 }
        return Int((Double(scope.reduce(0) { $0 + $1.peak }) / Double(scope.count)).rounded())
    }
    private var avgRecovery: Int {
        guard !scope.isEmpty else { return 0 }
        return Int((Double(scope.reduce(0) { $0 + $1.recovery }) / Double(scope.count)).rounded())
    }
    private var zone4Total: Int { scope.reduce(0) { $0 + $1.zone4Minutes } }

    // Fitness trend: lower resting-effort proxy = fitter. Deterministic synthetic curve.
    private var trend: [Double] {
        genSeries(48, base: 150, amp: 60, seed: 41).enumerated().map { i, _ in
            150 - (Double(i) / 48) * 55 + sin(Double(i) / 4) * 6
        }
    }
    // Rolling weekly load: minutes-in-zone weighted per session, last 7 buckets.
    private var load: [Double] {
        let recent = Array(sessions.prefix(7).reversed())
        let vals = recent.map { Double($0.durationSeconds) / 60 + Double($0.zone4Minutes) }
        return vals.isEmpty ? [40, 62, 50, 80, 70, 95, 60] : vals
    }
    private var loadScore: Int { Int(load.reduce(0, +).rounded()) }

    private var bests: [(String, String, String)] {
        let peak = sessions.map(\.peak).max() ?? 0
        let recovery = sessions.map(\.recovery).min() ?? 0
        let z4 = sessions.map(\.zone4Minutes).max() ?? 0
        return [
            ("PR peak HR", "\(peak) bpm", "flame.fill"),
            ("Fastest recovery", "\(recovery) bpm/min", "arrow.down"),
            ("Most Zone 4+", "\(z4) min", "trophy.fill"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(title: "Your trend", eyebrow: "Athlete", large: true) {
                    IconButton(systemName: "gearshape") { router.push(.settings) }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Segmented(options: [
                        SegmentOption(value: "week", label: "THIS WEEK"),
                        SegmentOption(value: "all", label: "ALL TIME"),
                    ], selection: $range)

                    HStack(spacing: 10) {
                        StatTile(label: "Sessions", value: "\(scope.count)",
                                 sub: range == "week" ? "this week" : "all time")
                        StatTile(label: "Avg peak", value: "\(avgPeak)", unit: "bpm", accent: true)
                    }
                    HStack(spacing: 10) {
                        StatTile(label: "Avg recovery", value: "\(avgRecovery)", unit: "bpm/m", trend: "faster")
                        StatTile(label: "Zone 4+", value: "\(zone4Total)", unit: "min")
                    }

                    // Fitness trend
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Eyebrow("Fitness trend")
                            Spacer()
                            Text("lower = fitter").font(RC.mono(10)).foregroundStyle(RC.good)
                        }
                        .padding(.bottom, 12)
                        HRGraph(series: trend, minY: 85, maxY: 160,
                                stroke: RC.good, area: RC.good, grid: false)
                            .frame(height: 84)
                        HStack {
                            Text("12 wks ago").font(RC.mono(9.5)).foregroundStyle(RC.text3)
                            Spacer()
                            Text("now").font(RC.mono(9.5)).foregroundStyle(RC.text3)
                        }
                        .padding(.top, 8)
                    }
                    .rcCard(16)

                    // Rolling load
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow("Rolling load")
                            LoadBars(vals: load)
                        }
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(loadScore)").font(RC.mono(28, .semibold)).foregroundStyle(RC.text)
                            Text("Optimal")
                                .font(RC.mono(10.5))
                                .foregroundStyle(RC.good)
                                .padding(.vertical, 3).padding(.horizontal, 10)
                                .overlay(Capsule().strokeBorder(RC.good.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .rcCard(16)

                    Eyebrow("Personal bests")
                    VStack(spacing: 10) {
                        ForEach(bests, id: \.0) { b in
                            HStack(spacing: 12) {
                                Image(systemName: b.2)
                                    .font(.system(size: 17))
                                    .foregroundStyle(RC.hr)
                                    .frame(width: 34, height: 34)
                                    .background(RC.hrDim, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Text(b.0).font(.system(size: 14)).foregroundStyle(RC.text2)
                                Spacer()
                                Text(b.1).font(RC.mono(14, .semibold)).foregroundStyle(RC.hr)
                            }
                            .rcCard2(14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Rolling load bars

struct LoadBars: View {
    var vals: [Double]

    var body: some View {
        let maxV = max(1, vals.max() ?? 1)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(vals.enumerated()), id: \.offset) { i, v in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(i == vals.count - 2 ? RC.hr : RC.surface3)
                    .frame(height: max(4, 46 * CGFloat(v / maxV)))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 46)
    }
}
