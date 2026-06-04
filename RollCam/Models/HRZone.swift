import SwiftUI

// Five HR zones, cool -> hot. Thresholds ported from the prototype (ui.jsx
// zoneIndex) as a fraction of an assumed max HR.
enum HRZone {
    static let names = ["Recovery", "Easy", "Aerobic", "Threshold", "Max"]

    static func index(_ bpm: Double, max: Double = 195) -> Int {
        let pct = bpm / max
        switch pct {
        case ..<0.62: return 0
        case ..<0.72: return 1
        case ..<0.82: return 2
        case ..<0.90: return 3
        default:      return 4
        }
    }

    static func index(_ bpm: Int, max: Double = 195) -> Int { index(Double(bpm), max: max) }

    static func color(_ i: Int) -> Color { RC.zones[min(Swift.max(i, 0), 4)] }
    static func name(_ i: Int) -> String { names[min(Swift.max(i, 0), 4)] }
}
