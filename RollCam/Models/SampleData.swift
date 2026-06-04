import Foundation
import SwiftData

// Deterministic wandering HR series — ported from the prototype (data.jsx genSeries).
func genSeries(_ len: Int, base: Double, amp: Double, seed: Int = 1) -> [Double] {
    var s = Double(seed)
    func rnd() -> Double {
        s = (s * 9301 + 49297).truncatingRemainder(dividingBy: 233280)
        return s / 233280
    }
    var cur = base - amp * 0.4
    var out: [Double] = []
    out.reserveCapacity(len)
    for i in 0..<len {
        let ramp = min(1, Double(i) / (Double(len) * 0.25))
        let target = base - amp * 0.5 + amp * ramp + sin(Double(i) / 6) * amp * 0.35
        cur += (target - cur) * 0.25 + (rnd() - 0.45) * amp * 0.18
        out.append(min(198, max(120, cur)))
    }
    return out
}

enum SampleData {

    private static func daysAgo(_ d: Int, hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: -d, to: Date()) ?? Date()
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }

    static func seedIfNeeded(into context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Session>())) ?? 0
        guard count == 0 else { return }
        for s in makeSessions() { context.insert(s) }
        try? context.save()
    }

    static func makeSessions() -> [Session] {
        let s1 = Session(
            title: "Evening Roll",
            date: daysAgo(1, hour: 19, minute: 30),
            durationSeconds: 18 * 60 + 42,
            rounds: 3, peak: 194, avg: 181, recovery: -22, zone4Minutes: 38,
            dist: [4, 10, 22, 34, 30],
            series: genSeries(60, base: 178, amp: 30, seed: 7),
            noteTags: ["Scramble", "Bad pos"],
            tagged: [
                TagMarker(timeLabel: "00:42", tag: "Sweep",      symbol: "arrow.triangle.2.circlepath", bpm: 152, pos: 0.07),
                TagMarker(timeLabel: "03:18", tag: "Bad pos",    symbol: "shield",                      bpm: 178, pos: 0.30),
                TagMarker(timeLabel: "08:40", tag: "Scramble",   symbol: "bolt.fill",                   bpm: 191, pos: 0.46),
                TagMarker(timeLabel: "14:02", tag: "Submission", symbol: "figure.martial.arts",         bpm: 184, pos: 0.74),
            ],
            roundCurves: [
                RoundCurve(label: "R1", peak: 194, series: genSeries(34, base: 184, amp: 16, seed: 3),  colorHex: 0xFF4B3A),
                RoundCurve(label: "R2", peak: 188, series: genSeries(34, base: 176, amp: 14, seed: 11), colorHex: 0xF3F5F9),
                RoundCurve(label: "R3", peak: 176, series: genSeries(34, base: 166, amp: 16, seed: 21), colorHex: 0x626B7B),
            ],
            pressure: [
                PressureMoment(label: "R2 · 3:20", note: "Scramble — HR 188->194", pos: 0.42),
                PressureMoment(label: "R3 · 1:05", note: "Heavy pressure, stuck",   pos: 0.78),
            ]
        )

        let s2 = Session(
            title: "Open Mat",
            date: daysAgo(2, hour: 12, minute: 10),
            durationSeconds: 42 * 60 + 10,
            rounds: 6, peak: 188, avg: 174, recovery: -19, zone4Minutes: 51,
            dist: [8, 16, 28, 30, 18],
            series: genSeries(60, base: 172, amp: 28, seed: 13),
            noteTags: ["Submission", "Sweep"]
        )

        let s3 = Session(
            title: "Comp Class",
            date: daysAgo(4, hour: 10, minute: 0),
            durationSeconds: 31 * 60 + 5,
            rounds: 5, peak: 191, avg: 178, recovery: -24, zone4Minutes: 44,
            dist: [5, 12, 24, 32, 27],
            series: genSeries(60, base: 176, amp: 30, seed: 29),
            noteTags: ["Scramble"]
        )

        let s4 = Session(
            title: "Drilling",
            date: daysAgo(6, hour: 18, minute: 0),
            durationSeconds: 24 * 60 + 30,
            rounds: 4, peak: 172, avg: 158, recovery: -27, zone4Minutes: 18,
            dist: [18, 30, 28, 16, 8],
            series: genSeries(60, base: 156, amp: 26, seed: 5),
            noteTags: ["Sweep"]
        )

        return [s1, s2, s3, s4]
    }
}
