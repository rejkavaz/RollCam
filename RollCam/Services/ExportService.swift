import Foundation

// Open data export. The athlete's HR data is theirs — exportable as plain CSV.
enum ExportService {

    /// Build a CSV of the session's HR series and write it to a temp file.
    /// Returns the file URL for a share sheet, or nil on failure.
    static func writeCSV(for s: Session) -> URL? {
        var rows = ["time_s,bpm,zone,zone_name"]
        let n = max(1, s.series.count)
        let spacing = Double(s.durationSeconds) / Double(n)
        for (i, v) in s.series.enumerated() {
            let t = Int(Double(i) * spacing)
            let z = HRZone.index(v)
            rows.append("\(t),\(Int(v.rounded())),\(z + 1),\(HRZone.name(z))")
        }
        let csv = rows.joined(separator: "\n")

        let safeTitle = s.title.replacingOccurrences(of: " ", with: "_")
        let name = "RollCam-\(safeTitle)-\(Int(s.date.timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
