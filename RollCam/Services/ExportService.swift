import Foundation
import AVFoundation
import CoreImage
import UIKit

// Open data export plus on-device video rendering.
//
// Everything here runs locally with AVFoundation + Core Image — no network, no
// AI. CSV is the athlete's raw HR data; `renderClip` burns the deterministic HR
// overlay (and an optional on-device face blur) into a new .mov the user can
// share. Nothing leaves the device until the share sheet hands it off.
enum ExportService {

    enum ExportError: LocalizedError {
        case noVideo, noVideoTrack, exportFailed

        var errorDescription: String? {
            switch self {
            case .noVideo:      return "This session has no recorded video to export."
            case .noVideoTrack: return "The recording is missing a video track."
            case .exportFailed: return "The clip couldn't be rendered. Please try again."
            }
        }
    }

    // MARK: - CSV

    /// Build a CSV of the session's HR series and write it to a temp file.
    /// Returns the file URL for a share sheet, or nil on failure.
    static func writeCSV(for s: Session) -> URL? {
        var rows = ["time_s,bpm,zone,zone_name"]
        let n = max(1, s.series.count)
        let spacing = Double(s.durationSeconds) / Double(n)
        let mh = Double(s.maxHR)
        for (i, v) in s.series.enumerated() {
            let t = Int(Double(i) * spacing)
            let z = HRZone.index(v, max: mh)
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

    // MARK: - Video render

    /// Render the session's recording with a burned-in HR overlay and, optionally,
    /// an on-device face blur. Calls `progress` (0...1) on the main thread and
    /// finishes with the rendered file URL or an error.
    static func renderClip(for s: Session,
                           style: String,
                           blurFaces: Bool,
                           progress: @escaping (Double) -> Void,
                           completion: @escaping (Result<URL, Error>) -> Void) {
        guard let path = s.videoPath, FileManager.default.fileExists(atPath: path) else {
            completion(.failure(ExportError.noVideo)); return
        }
        let srcURL = URL(fileURLWithPath: path)

        // Snapshot the value types the renderer needs so we don't touch the
        // SwiftData model off the main actor.
        let snapshot = Snapshot(series: s.series,
                                durationSeconds: s.durationSeconds,
                                peak: s.peak, avg: s.avg, maxHR: s.maxHR,
                                title: s.title, date: s.date)

        Task.detached(priority: .userInitiated) {
            do {
                let url = try await render(srcURL: srcURL, snap: snapshot,
                                           style: style, blurFaces: blurFaces) { p in
                    Task { @MainActor in progress(p) }
                }
                await MainActor.run { completion(.success(url)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }

    private struct Snapshot: Sendable {
        let series: [Double]
        let durationSeconds: Int
        let peak: Int
        let avg: Int
        let maxHR: Int
        let title: String
        let date: Date
    }

    private static func render(srcURL: URL, snap: Snapshot, style: String,
                               blurFaces: Bool,
                               progress: @escaping (Double) -> Void) async throws -> URL {
        // Two passes: an optional Core Image face-blur pass, then the overlay
        // pass that burns the HR graph + playhead via a Core Animation tool.
        var working = srcURL
        if blurFaces {
            working = try await blurPass(working) { progress($0 * 0.5) }
        }
        let blurWeight = blurFaces ? 0.5 : 0.0
        return try await overlayPass(working, snap: snap, style: style) {
            progress(blurWeight + $0 * (1 - blurWeight))
        }
    }

    // MARK: Pass 1 — face blur (Core Image)

    private static func blurPass(_ url: URL,
                                 progress: @escaping (Double) -> Void) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyLow])

        let comp = AVMutableVideoComposition(asset: asset) { request in
            let src = request.sourceImage
            let faces = detector?.features(in: src) ?? []
            guard !faces.isEmpty else {
                request.finish(with: src, context: nil); return
            }
            // Pixellate the whole frame, then keep only the face regions via a mask.
            let scale = max(src.extent.width, src.extent.height) / 36
            let pixellated = src
                .applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: scale])
                .cropped(to: src.extent)

            var mask = CIImage(color: .black).cropped(to: src.extent)
            for f in faces {
                let r = f.bounds.insetBy(dx: -f.bounds.width * 0.12,
                                         dy: -f.bounds.height * 0.12)
                let blob = CIImage(color: .white).cropped(to: r)
                mask = blob.composited(over: mask)
            }
            let blurredMask = mask.applyingFilter("CIGaussianBlur",
                                                  parameters: [kCIInputRadiusKey: 12])
                .cropped(to: src.extent)
            let out = pixellated.applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: src,
                kCIInputMaskImageKey: blurredMask,
            ]).cropped(to: src.extent)
            request.finish(with: out, context: nil)
        }

        let out = tempURL(prefix: "blur")
        guard let export = AVAssetExportSession(asset: asset,
                                                presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.exportFailed
        }
        export.videoComposition = comp
        export.outputURL = out
        export.outputFileType = .mov
        try await runExport(export, progress: progress)
        return out
    }

    // MARK: Pass 2 — HR overlay (Core Animation)

    private static func overlayPass(_ url: URL, snap: Snapshot, style: String,
                                    progress: @escaping (Double) -> Void) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.noVideoTrack
        }
        let natural = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let duration = try await asset.load(.duration)
        let renderSize = orientedSize(natural, transform)

        let composition = AVMutableComposition()
        guard let vTrack = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ExportError.exportFailed
        }
        try vTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration),
                                   of: track, at: .zero)

        if let aTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let audio = composition.addMutableTrack(
               withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? audio.insertTimeRange(CMTimeRange(start: .zero, duration: duration),
                                       of: aTrack, at: .zero)
        }

        // Core Animation overlay tree (Core Animation geometry: origin bottom-left).
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: renderSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: renderSize)
        buildOverlay(on: overlayLayer, size: renderSize, snap: snap, style: style,
                     duration: CMTimeGetSeconds(duration))
        let parent = CALayer()
        parent.frame = CGRect(origin: .zero, size: renderSize)
        parent.addSublayer(videoLayer)
        parent.addSublayer(overlayLayer)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer, in: parent)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
        layerInstruction.setTransform(transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let out = tempURL(prefix: "clip")
        guard let export = AVAssetExportSession(asset: composition,
                                                presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.exportFailed
        }
        export.videoComposition = videoComposition
        export.outputURL = out
        export.outputFileType = .mov
        try await runExport(export, progress: progress)
        return out
    }

    // MARK: Overlay drawing

    private static func buildOverlay(on layer: CALayer, size: CGSize,
                                     snap: Snapshot, style: String, duration: Double) {
        let w = size.width, h = size.height
        let unit = min(w, h)

        // Cinematic: a soft bottom-up tint so the readout sits on a darker base.
        if style == "cinematic" {
            let grad = CAGradientLayer()
            grad.frame = CGRect(x: 0, y: 0, width: w, height: h)
            grad.colors = [
                UIColor(red: 1, green: 0.29, blue: 0.23, alpha: 0.22).cgColor,
                UIColor.clear.cgColor,
            ]
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint = CGPoint(x: 0, y: 0.55)
            layer.addSublayer(grad)
        }

        // Minimal / coach: a compact badge in the top-right corner only.
        if style == "minimal" || style == "coach" {
            let badgeH = max(unit * 0.072, 54)
            let pad = unit * 0.03
            let text = style == "coach" ? "♥ \(snap.peak) · Z4 PEAK" : "♥ \(snap.peak)"
            let est = CGFloat(text.count) * badgeH * 0.42 + badgeH * 0.7
            let badge = CALayer()
            badge.frame = CGRect(x: w - est - pad, y: h - badgeH - pad,
                                 width: est, height: badgeH)
            badge.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
            badge.cornerRadius = badgeH * 0.28
            badge.borderWidth = 1
            badge.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
            badge.addSublayer(textLayer(text, size: badgeH * 0.42,
                                        color: .white, frame: badge.bounds,
                                        align: .center))
            layer.addSublayer(badge)
            return
        }

        // Cinematic / data: a bottom readout bar with the full HR graph + playhead.
        let barH = max(h * 0.16, unit * 0.18)
        let bar = CALayer()
        bar.frame = CGRect(x: 0, y: 0, width: w, height: barH)
        if style == "data" {
            bar.backgroundColor = UIColor.black.withAlphaComponent(0.55).cgColor
        }
        layer.addSublayer(bar)

        let inset = unit * 0.04
        let captionH = barH * 0.34

        // Peak / avg caption.
        let caption = "PEAK \(snap.peak)   ·   AVG \(snap.avg) bpm"
        bar.addSublayer(textLayer(caption, size: captionH * 0.62,
                                  color: UIColor(red: 1, green: 0.29, blue: 0.23, alpha: 1),
                                  frame: CGRect(x: inset, y: barH - captionH - inset * 0.3,
                                                width: w - inset * 2, height: captionH),
                                  align: .left, bold: true))

        // HR graph path across the bar.
        let graphRect = CGRect(x: inset, y: inset * 0.6,
                               width: w - inset * 2,
                               height: barH - captionH - inset)
        let series = snap.series
        if series.count > 1 {
            let lo = series.min() ?? 60, hi = series.max() ?? 200
            let span = max(1, hi - lo)
            let path = CGMutablePath()
            for (i, v) in series.enumerated() {
                let x = graphRect.minX + graphRect.width * CGFloat(i) / CGFloat(series.count - 1)
                let y = graphRect.minY + graphRect.height * CGFloat((v - lo) / span)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            let line = CAShapeLayer()
            line.path = path
            line.strokeColor = UIColor(red: 1, green: 0.29, blue: 0.23, alpha: 0.9).cgColor
            line.fillColor = UIColor.clear.cgColor
            line.lineWidth = max(2, unit * 0.004)
            line.lineJoin = .round
            line.lineCap = .round
            bar.addSublayer(line)

            // A vertical playhead that sweeps left→right in sync with playback.
            let head = CALayer()
            head.backgroundColor = UIColor.white.cgColor
            let headW = max(1.5, unit * 0.003)
            head.frame = CGRect(x: graphRect.minX, y: inset * 0.6,
                                width: headW, height: graphRect.height)
            head.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            head.position = CGPoint(x: graphRect.minX, y: inset * 0.6 + graphRect.height / 2)

            let sweep = CABasicAnimation(keyPath: "position.x")
            sweep.fromValue = graphRect.minX
            sweep.toValue = graphRect.maxX
            sweep.duration = max(0.1, duration)
            sweep.beginTime = AVCoreAnimationBeginTimeAtZero
            sweep.isRemovedOnCompletion = false
            sweep.fillMode = .both
            head.add(sweep, forKey: "sweep")
            bar.addSublayer(head)
        }
    }

    private enum TextAlign { case left, center }

    private static func textLayer(_ string: String, size: CGFloat, color: UIColor,
                                  frame: CGRect, align: TextAlign,
                                  bold: Bool = false) -> CATextLayer {
        let t = CATextLayer()
        t.string = string
        t.font = UIFont.monospacedSystemFont(ofSize: size, weight: bold ? .semibold : .regular)
        t.fontSize = size
        t.foregroundColor = color.cgColor
        t.alignmentMode = align == .center ? .center : .left
        t.contentsScale = 3
        t.isWrapped = false
        t.truncationMode = .none
        // Vertically center the single line within the frame.
        let lineH = size * 1.25
        t.frame = CGRect(x: frame.minX, y: frame.midY - lineH / 2,
                         width: frame.width, height: lineH)
        return t
    }

    // MARK: Helpers

    /// Natural size after applying the track's preferred transform (handles
    /// portrait recordings whose stored buffers are landscape).
    private static func orientedSize(_ natural: CGSize, _ t: CGAffineTransform) -> CGSize {
        let r = CGRect(origin: .zero, size: natural).applying(t)
        return CGSize(width: abs(r.width), height: abs(r.height))
    }

    private static func tempURL(prefix: String) -> URL {
        let name = "RollCam-\(prefix)-\(Int(Date().timeIntervalSince1970)).mov"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        return url
    }

    /// Run an export session, reporting progress, and resume when it finishes.
    private static func runExport(_ export: AVAssetExportSession,
                                  progress: @escaping (Double) -> Void) async throws {
        let poll = Task {
            while !Task.isCancelled {
                let p = export.progress
                progress(Double(p))
                if p >= 1 { break }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        defer { poll.cancel() }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            export.exportAsynchronously {
                switch export.status {
                case .completed:
                    cont.resume()
                case .failed, .cancelled:
                    cont.resume(throwing: export.error ?? ExportError.exportFailed)
                default:
                    cont.resume(throwing: ExportError.exportFailed)
                }
            }
        }
        progress(1)
    }
}
