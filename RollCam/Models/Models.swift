import Foundation
import SwiftData

// MARK: - Value types stored on a Session (Codable -> persisted by SwiftData)

/// A moment the athlete tagged during post-review.
struct TagMarker: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var timeLabel: String   // "03:18"
    var tag: String         // "Scramble"
    var symbol: String      // SF Symbol name
    var bpm: Int
    var pos: Double         // 0...1 position along the HR series
}

/// One round's HR curve, used by the round-comparison overlay.
struct RoundCurve: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String       // "R1"
    var peak: Int
    var series: [Double]
    var colorHex: UInt32     // resolved to a Color in the view layer
}

/// A rule-based "pressure moment" — a detected HR spike, no ML involved.
struct PressureMoment: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String       // "R2 · 3:20"
    var note: String        // "Scramble — HR 188->194"
    var pos: Double         // 0...1
}

// MARK: - Session

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var durationSeconds: Int
    var rounds: Int

    // Derived HR metrics (computed at save time from the series).
    var peak: Int
    var avg: Int
    var recovery: Int          // bpm/min, negative = drop between rounds
    var zone4Minutes: Int
    var maxHR: Int = 195       // athlete's max HR used for this session's zone math

    var dist: [Int]            // time-in-zone distribution, 5 buckets
    var series: [Double]       // whole-session HR samples
    var noteTags: [String]     // short labels shown on the library card
    var tagged: [TagMarker]    // markers dropped in post-review
    var roundCurves: [RoundCurve]
    var pressure: [PressureMoment]

    var partner: String?
    var videoPath: String?     // local file URL, if a real recording was captured
    var voiceNotePath: String?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        durationSeconds: Int,
        rounds: Int,
        peak: Int,
        avg: Int,
        recovery: Int,
        zone4Minutes: Int,
        maxHR: Int = 195,
        dist: [Int],
        series: [Double],
        noteTags: [String] = [],
        tagged: [TagMarker] = [],
        roundCurves: [RoundCurve] = [],
        pressure: [PressureMoment] = [],
        partner: String? = nil,
        videoPath: String? = nil,
        voiceNotePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationSeconds = durationSeconds
        self.rounds = rounds
        self.peak = peak
        self.avg = avg
        self.recovery = recovery
        self.zone4Minutes = zone4Minutes
        self.maxHR = maxHR
        self.dist = dist
        self.series = series
        self.noteTags = noteTags
        self.tagged = tagged
        self.roundCurves = roundCurves
        self.pressure = pressure
        self.partner = partner
        self.videoPath = videoPath
        self.voiceNotePath = voiceNotePath
    }

    // MARK: Display helpers

    var durationLabel: String { Self.clock(durationSeconds) }
    var dayLabel: String { Session.weekdayFormatter.string(from: date) }
    var dateLabel: String { Session.dayMonthFormatter.string(from: date) }
    var timeLabel: String { Session.timeFormatter.string(from: date) }

    static func clock(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()
    static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
}
