import Foundation

// Rule-based session analysis. Everything here is deterministic arithmetic
// over the HR series — no machine learning, no AI, no network calls.

enum SessionAnalytics {

    // MARK: Metrics from a raw recorded series

    struct Metrics {
        var peak: Int
        var avg: Int
        var recovery: Int
        var zone4Minutes: Int
        var dist: [Int]
    }

    /// Derive a session's summary metrics from its HR samples.
    /// `sampleSpacing` is the seconds represented by each sample.
    static func metrics(series: [Double], durationSeconds: Int) -> Metrics {
        guard !series.isEmpty else {
            return Metrics(peak: 0, avg: 0, recovery: 0, zone4Minutes: 0, dist: [0, 0, 0, 0, 0])
        }
        let peak = Int(series.max() ?? 0)
        let avg = Int((series.reduce(0, +) / Double(series.count)).rounded())

        // Time-in-zone distribution (5 buckets), as integer percentages.
        var counts = [Int](repeating: 0, count: 5)
        for v in series { counts[HRZone.index(v)] += 1 }
        let total = max(1, series.count)
        let dist = counts.map { Int((Double($0) / Double(total) * 100).rounded()) }

        // Zone 4+ minutes.
        let secondsPerSample = Double(durationSeconds) / Double(series.count)
        let z4samples = series.filter { HRZone.index($0) >= 3 }.count
        let zone4Minutes = Int((Double(z4samples) * secondsPerSample / 60).rounded())

        // Recovery proxy: average drop over the steepest sustained descent.
        let recovery = recoveryRate(series: series, secondsPerSample: secondsPerSample)

        return Metrics(peak: peak, avg: avg, recovery: recovery, zone4Minutes: zone4Minutes, dist: dist)
    }

    /// Fastest sustained HR drop, expressed as bpm/min (negative number).
    private static func recoveryRate(series: [Double], secondsPerSample: Double) -> Int {
        guard series.count > 4 else { return 0 }
        // ~1 minute of samples, but never wider than the series itself — otherwise
        // `series.count - window` goes negative and `0..<negative` traps at runtime
        // (this was the crash when stopping a short recording).
        let window = min(series.count - 1, max(2, Int(60 / max(1, secondsPerSample))))
        guard window >= 1, series.count - window > 0 else { return 0 }
        var best = 0.0
        for i in 0..<(series.count - window) {
            let drop = series[i] - series[i + window]
            if drop > best { best = drop }
        }
        let perMinute = best / (Double(window) * secondsPerSample / 60)
        guard perMinute.isFinite else { return 0 }
        return -Int(perMinute.rounded())
    }

    // MARK: Per-round curves (for the Round Compare overlay)

    /// Slice the recorded series into `rounds` contiguous segments so each round's
    /// HR curve can be overlaid. Purely a reshape of the real samples — no synthesis.
    static func roundCurves(series: [Double], rounds: Int) -> [RoundCurve] {
        guard rounds > 1, series.count >= rounds * 2 else { return [] }
        // Cool -> hot legend colours, reused cyclically if there are many rounds.
        let palette: [UInt32] = [0xFF4B3A, 0xF3F5F9, 0x6EA8FF, 0x6BE08F, 0xE0B15A, 0x626B7B]
        let per = series.count / rounds
        var out: [RoundCurve] = []
        for r in 0..<rounds {
            let lo = r * per
            let hi = (r == rounds - 1) ? series.count : (r + 1) * per
            let slice = Array(series[lo..<hi])
            guard !slice.isEmpty else { continue }
            out.append(RoundCurve(
                label: "R\(r + 1)",
                peak: Int(slice.max() ?? 0),
                series: slice,
                colorHex: palette[r % palette.count]
            ))
        }
        return out
    }

    // MARK: Pressure moments (HR spikes) — rule-based, no ML

    /// Detect sharp upward HR excursions and label them by approximate round/time.
    static func detectPressure(series: [Double], durationSeconds: Int, rounds: Int) -> [PressureMoment] {
        guard series.count > 6 else { return [] }
        let look = max(2, series.count / 20)
        var moments: [PressureMoment] = []
        var i = look
        while i < series.count - 1 {
            let rise = series[i] - series[i - look]
            let isLocalHigh = series[i] >= series[i - 1] && series[i] >= series[min(series.count - 1, i + 1)]
            if rise >= 12 && series[i] >= 175 && isLocalHigh {
                let pos = Double(i) / Double(series.count - 1)
                let secs = Int(pos * Double(durationSeconds))
                let round = min(rounds, Int(pos * Double(rounds)) + 1)
                let from = Int(series[i - look]), to = Int(series[i])
                moments.append(PressureMoment(
                    label: "R\(round) · \(Session.clock(secs))",
                    note: "HR \(from)->\(to)",
                    pos: pos
                ))
                i += look * 2   // de-dupe nearby spikes
            } else {
                i += 1
            }
        }
        return Array(moments.prefix(4))
    }

    // MARK: Deterministic text breakdown (replaces the prototype's AI summary)

    static func breakdown(for s: Session) -> String {
        guard !s.series.isEmpty else { return "No heart-rate data was captured for this session." }
        let n = s.series.count
        let peakIdx = s.series.firstIndex(of: s.series.max() ?? 0) ?? 0
        let peakPos = Double(peakIdx) / Double(max(1, n - 1))
        let peakSecs = Int(peakPos * Double(s.durationSeconds))
        let peakRound = min(s.rounds, Int(peakPos * Double(s.rounds)) + 1)

        let threshold = 160.0
        let aboveCount = s.series.filter { $0 >= threshold }.count
        let abovePct = Int((Double(aboveCount) / Double(n) * 100).rounded())

        var parts: [String] = []
        parts.append("HR peaked at \(s.peak) bpm around \(Session.clock(peakSecs)) (round \(peakRound)).")
        parts.append("You held above \(Int(threshold)) bpm for \(abovePct)% of mat time.")
        if s.recovery <= -25 {
            parts.append("Between-round recovery was strong at \(s.recovery) bpm/min.")
        } else if s.recovery >= -15 {
            parts.append("Recovery between rounds was slow (\(s.recovery) bpm/min) — a sign you were gassing.")
        } else {
            parts.append("Recovery between rounds averaged \(s.recovery) bpm/min.")
        }
        if s.zone4Minutes >= 35 {
            parts.append("That's \(s.zone4Minutes) min in Zone 4+, a high-intensity session.")
        }
        return parts.joined(separator: " ")
    }

    static func fatigueNote(curves: [RoundCurve]) -> String {
        guard let first = curves.first, let last = curves.last, curves.count > 1 else {
            return "Not enough rounds to compare."
        }
        return "Peak HR dropped \(first.peak) -> \(last.peak) across rounds and your curve flattens earlier each round — a classic fatigue pattern."
    }
}
