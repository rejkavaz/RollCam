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
        guard let srcURL = s.videoURL else {
            completion(.failure(ExportError.noVideo)); return
        }

        // Snapshot the value types the renderer needs so we don't touch the
        // SwiftData model off the main actor.
        let events = s.tagged.map {
            Event(pos: $0.pos, label: $0.tag, timeLabel: $0.timeLabel, bpm: $0.bpm)
        }
        let snapshot = Snapshot(series: s.series,
                                durationSeconds: s.durationSeconds,
                                peak: s.peak, avg: s.avg, maxHR: s.maxHR,
                                title: s.title, date: s.date, events: events)

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
        let events: [Event]
    }

    /// A tagged moment to surface as a timed notification banner in the render.
    private struct Event: Sendable {
        let pos: Double      // 0...1 along the clip
        let label: String    // "Sweep"
        let timeLabel: String// "2:14"
        let bpm: Int
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
    //
    // All layers use the AVVideoCompositionCoreAnimationTool coordinate space:
    // origin bottom-left, y increasing upward. Styles are zone-aware — the
    // accent tints to the colour of the session's peak zone.

    private static func buildOverlay(on layer: CALayer, size: CGSize,
                                     snap: Snapshot, style: String, duration: Double) {
        let w = size.width, h = size.height
        let unit = min(w, h)
        let pad = unit * 0.045
        let zone = zoneColor(snap.peak, snap.maxHR)

        switch style {
        case "minimal": buildMinimal(layer, w: w, h: h, unit: unit, pad: pad, snap: snap, zone: zone, duration: duration)
        case "coach":   buildCoach(layer, w: w, h: h, unit: unit, pad: pad, snap: snap, zone: zone, duration: duration)
        case "data":    buildData(layer, w: w, h: h, unit: unit, pad: pad, snap: snap, zone: zone, duration: duration)
        default:        buildCinematic(layer, w: w, h: h, unit: unit, pad: pad, snap: snap, zone: zone, duration: duration)
        }

        // Timed event notifications float in over every style at their moment.
        buildEvents(on: layer, w: w, h: h, unit: unit, pad: pad, snap: snap, duration: duration)
    }

    // MARK: Event notifications — a banner that slides in at each tagged moment.

    private static func buildEvents(on layer: CALayer, w: CGFloat, h: CGFloat, unit: CGFloat,
                                    pad: CGFloat, snap: Snapshot, duration: Double) {
        guard !snap.events.isEmpty, duration > 0.2 else { return }

        let bannerH = unit * 0.085
        // Top-left, which stays clear across all four styles (the chips live
        // top-right; the bars/lockups live along the bottom).
        let bannerW = min(w - pad * 2, unit * 0.46)
        let bx = pad
        // Sit just below the top edge (origin is bottom-left, so high y = top).
        let by = h - pad * 1.3 - bannerH

        let showFrac = min(0.45, 2.6 / duration)          // visible window
        let fadeFrac = min(showFrac * 0.35, 0.45 / duration)

        for ev in snap.events {
            let zone = zoneColor(ev.bpm, snap.maxHR)
            let banner = card(CGRect(x: bx, y: by, width: bannerW, height: bannerH),
                              radius: bannerH * 0.28, fill: .black, alpha: 0.62,
                              border: UIColor.white.withAlphaComponent(0.18))
            banner.opacity = 0

            // Leading accent dot.
            let dotR = bannerH * 0.11
            let dotX = bannerH * 0.34
            let dot = CALayer()
            dot.frame = CGRect(x: dotX, y: bannerH / 2 - dotR, width: dotR * 2, height: dotR * 2)
            dot.cornerRadius = dotR
            dot.backgroundColor = zone.cgColor
            dot.shadowColor = zone.cgColor; dot.shadowRadius = dotR * 1.5
            dot.shadowOpacity = 0.9; dot.shadowOffset = .zero
            banner.addSublayer(dot)

            let textX = dotX + dotR * 2 + bannerH * 0.28
            let textW = bannerW - textX - bannerH * 0.3
            banner.addSublayer(text(ev.label.uppercased(), fontSize: bannerH * 0.32, weight: .bold,
                                    color: .white,
                                    frame: CGRect(x: textX, y: bannerH * 0.5, width: textW, height: bannerH * 0.44)))
            banner.addSublayer(text("\(ev.timeLabel) · \(ev.bpm) BPM", fontSize: bannerH * 0.18, weight: .medium,
                                    mono: true, color: UIColor.white.withAlphaComponent(0.7), tracking: bannerH * 0.01,
                                    frame: CGRect(x: textX, y: bannerH * 0.16, width: textW, height: bannerH * 0.26)))

            // Timed fade-in / hold / fade-out around the event's position.
            let f = min(max(ev.pos, 0.0), 1.0)
            var keyTimes: [Double] = [0]
            var values: [NSNumber] = [0]
            func push(_ kt: Double, _ v: Double) {
                let clamped = min(max(kt, 0), 1)
                if clamped > keyTimes.last! { keyTimes.append(clamped); values.append(NSNumber(value: v)) }
            }
            push(f, 0)
            push(f + fadeFrac, 1)
            push(f + showFrac, 1)
            push(f + showFrac + fadeFrac, 0)
            if keyTimes.last! < 1 { keyTimes.append(1); values.append(values.last!) }

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = values
            fade.keyTimes = keyTimes.map { NSNumber(value: $0) }
            fade.calculationMode = .linear
            fade.duration = duration
            fade.beginTime = AVCoreAnimationBeginTimeAtZero
            fade.isRemovedOnCompletion = false
            fade.fillMode = .both
            banner.add(fade, forKey: "fade")
            layer.addSublayer(banner)
        }
    }

    // MARK: Minimal — a single frosted HR chip, top-right.

    private static func buildMinimal(_ layer: CALayer, w: CGFloat, h: CGFloat, unit: CGFloat,
                                     pad: CGFloat, snap: Snapshot, zone: UIColor, duration: Double) {
        let cw = unit * 0.30, ch = unit * 0.165
        let chip = card(CGRect(x: w - cw - pad, y: h - ch - pad, width: cw, height: ch),
                        radius: ch * 0.26, fill: .black, alpha: 0.42,
                        border: UIColor.white.withAlphaComponent(0.18))
        layer.addSublayer(chip)

        chip.addSublayer(liveNumber(series: snap.series, fallback: snap.peak, fontSize: ch * 0.5,
                                    weight: .bold, color: .white, align: .center,
                                    frame: CGRect(x: 0, y: ch * 0.32, width: cw, height: ch * 0.55),
                                    duration: duration))
        chip.addSublayer(text("♥ LIVE BPM", fontSize: ch * 0.14, weight: .semibold, mono: true,
                              color: zone, tracking: ch * 0.02, align: .center,
                              frame: CGRect(x: 0, y: ch * 0.12, width: cw, height: ch * 0.2)))
    }

    // MARK: Coach — a richer badge with peak, zone pill and avg, top-right.

    private static func buildCoach(_ layer: CALayer, w: CGFloat, h: CGFloat, unit: CGFloat,
                                   pad: CGFloat, snap: Snapshot, zone: UIColor, duration: Double) {
        let cw = unit * 0.44, ch = unit * 0.225
        let x0 = w - cw - pad
        let chip = card(CGRect(x: x0, y: h - ch - pad, width: cw, height: ch),
                        radius: ch * 0.20, fill: .black, alpha: 0.5,
                        border: UIColor.white.withAlphaComponent(0.16))
        layer.addSublayer(chip)

        let zi = HRZone.index(snap.peak, max: Double(snap.maxHR))
        let insetX = ch * 0.22
        let insetY = ch * 0.18

        // Two clean horizontal bands inside the chip (origin bottom-left):
        // a number row up top, a caption row underneath.
        let captionH = ch * 0.20
        let gap = ch * 0.07
        let numRowH = ch - insetY * 2 - captionH - gap
        let numRowY = insetY + captionH + gap   // bottom edge of the number row

        // Heart dot, vertically centred on the number row.
        let dotR = numRowH * 0.15
        let dot = CALayer()
        dot.frame = CGRect(x: insetX, y: numRowY + numRowH / 2 - dotR, width: dotR * 2, height: dotR * 2)
        dot.cornerRadius = dotR
        dot.backgroundColor = zone.cgColor
        dot.shadowColor = zone.cgColor; dot.shadowRadius = dotR * 1.6
        dot.shadowOpacity = 0.9; dot.shadowOffset = .zero
        chip.addSublayer(dot)

        // Zone pill on the right, vertically centred on the number row.
        let pillH = numRowH * 0.64, pillW = unit * 0.105
        let pillX = cw - insetX - pillW
        let pill = card(CGRect(x: pillX, y: numRowY + numRowH / 2 - pillH / 2, width: pillW, height: pillH),
                        radius: pillH * 0.5, fill: zone, alpha: 0.95, border: nil, shadow: false)
        chip.addSublayer(pill)
        pill.addSublayer(text("Z\(zi + 1)", fontSize: pillH * 0.46, weight: .heavy, mono: true,
                              color: .white, align: .center,
                              frame: CGRect(x: 0, y: 0, width: pillW, height: pillH)))

        // Big live number, filling the space between the dot and the pill.
        let numX = insetX + dotR * 2 + ch * 0.10
        chip.addSublayer(liveNumber(series: snap.series, fallback: snap.peak, fontSize: numRowH * 0.86,
                                    weight: .bold, color: .white,
                                    frame: CGRect(x: numX, y: numRowY,
                                                  width: pillX - numX - ch * 0.08, height: numRowH),
                                    duration: duration))

        // Caption row.
        chip.addSublayer(text("AVG \(snap.avg) · \(HRZone.name(zi).uppercased())",
                              fontSize: captionH * 0.66, weight: .medium, mono: true,
                              color: UIColor.white.withAlphaComponent(0.7), tracking: captionH * 0.03,
                              frame: CGRect(x: insetX, y: insetY, width: cw - insetX * 2, height: captionH)))
    }

    // MARK: Cinematic — full-frame scrims, a glowing HR ribbon + a bottom lockup.

    private static func buildCinematic(_ layer: CALayer, w: CGFloat, h: CGFloat, unit: CGFloat,
                                       pad: CGFloat, snap: Snapshot, zone: UIColor, duration: Double) {
        // Zone-tinted wash from the lower-left corner.
        let tint = CAGradientLayer()
        tint.frame = CGRect(x: 0, y: 0, width: w, height: h)
        tint.colors = [zone.withAlphaComponent(0.20).cgColor, UIColor.clear.cgColor]
        tint.startPoint = CGPoint(x: 0.0, y: 0.0)
        tint.endPoint = CGPoint(x: 0.6, y: 0.6)
        layer.addSublayer(tint)

        // Bottom legibility scrim.
        let scrim = CAGradientLayer()
        scrim.frame = CGRect(x: 0, y: 0, width: w, height: h * 0.4)
        scrim.colors = [UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.clear.cgColor]
        scrim.startPoint = CGPoint(x: 0.5, y: 0.0)
        scrim.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(scrim)

        // Glowing HR ribbon along the very bottom edge.
        let ribbonH = unit * 0.13
        layer.addSublayer(graphLayer(rect: CGRect(x: 0, y: 0, width: w, height: ribbonH),
                                     series: snap.series, color: zone,
                                     lineWidth: max(2.5, unit * 0.005),
                                     fill: true, dot: true, duration: duration))

        // Bottom-left lockup.
        let numH = unit * 0.105
        let numY = ribbonH + pad * 0.5
        layer.addSublayer(liveNumber(series: snap.series, fallback: snap.peak, fontSize: numH,
                                     weight: .bold, color: .white,
                                     frame: CGRect(x: pad, y: numY, width: w * 0.7, height: numH),
                                     duration: duration))
        layer.addSublayer(text("PEAK \(snap.peak) · AVG \(snap.avg) BPM", fontSize: unit * 0.026, weight: .semibold,
                               mono: true, color: zone, tracking: unit * 0.004,
                               frame: CGRect(x: pad + unit * 0.008, y: numY - unit * 0.034,
                                             width: w * 0.7, height: unit * 0.032)))
        layer.addSublayer(text("LIVE HEART RATE", fontSize: unit * 0.024, weight: .semibold, mono: true,
                               color: UIColor.white.withAlphaComponent(0.7), tracking: unit * 0.006,
                               frame: CGRect(x: pad + unit * 0.008, y: numY + numH - unit * 0.004,
                                             width: w * 0.7, height: unit * 0.03)))
    }

    // MARK: Data — a frosted bottom bar with stats and the full HR graph.

    private static func buildData(_ layer: CALayer, w: CGFloat, h: CGFloat, unit: CGFloat,
                                  pad: CGFloat, snap: Snapshot, zone: UIColor, duration: Double) {
        let barH = max(h * 0.16, unit * 0.2)
        let bar = CALayer()
        bar.frame = CGRect(x: 0, y: 0, width: w, height: barH)
        bar.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        layer.addSublayer(bar)
        // Accent hairline along the top edge of the bar.
        let hairH = max(1.5, unit * 0.003)
        let hair = CALayer()
        hair.frame = CGRect(x: 0, y: barH - hairH, width: w, height: hairH)
        hair.backgroundColor = zone.withAlphaComponent(0.85).cgColor
        layer.addSublayer(hair)

        let zi = HRZone.index(snap.peak, max: Double(snap.maxHR))
        let insetY = barH * 0.16

        // Three stacked rows in the left column (origin bottom-left): caption
        // label on top, the big live number in the middle, a sub-line beneath.
        let labelH = barH * 0.13
        let subH = barH * 0.13
        let gap = barH * 0.05
        let numH = barH - insetY * 2 - labelH - subH - gap * 2
        let numY = insetY + subH + gap
        let labelY = numY + numH + gap

        bar.addSublayer(text("LIVE HEART RATE", fontSize: labelH * 0.78, weight: .semibold, mono: true,
                             color: UIColor.white.withAlphaComponent(0.55), tracking: labelH * 0.06,
                             frame: CGRect(x: pad, y: labelY, width: w * 0.4, height: labelH)))

        // Big number + zone pill, inline on the number row.
        let numFont = numH * 0.92
        let numW = numFont * 1.7
        bar.addSublayer(liveNumber(series: snap.series, fallback: snap.peak, fontSize: numFont,
                                   weight: .bold, color: .white,
                                   frame: CGRect(x: pad, y: numY, width: numW, height: numH),
                                   duration: duration))
        let pillH = numH * 0.5, pillW = unit * 0.165
        let pill = card(CGRect(x: pad + numW + pad * 0.4, y: numY + numH / 2 - pillH / 2,
                               width: pillW, height: pillH),
                        radius: pillH * 0.5, fill: zone, alpha: 0.95, border: nil, shadow: false)
        bar.addSublayer(pill)
        pill.addSublayer(text("Z\(zi + 1) · \(HRZone.name(zi).uppercased())", fontSize: pillH * 0.42,
                              weight: .bold, mono: true, color: .white, align: .center,
                              frame: CGRect(x: 0, y: 0, width: pillW, height: pillH)))

        bar.addSublayer(text("PEAK \(snap.peak) · AVG \(snap.avg) BPM", fontSize: subH * 0.82, weight: .medium, mono: true,
                             color: zone, tracking: subH * 0.04,
                             frame: CGRect(x: pad, y: insetY, width: w * 0.48, height: subH)))

        // HR graph on the right half, with a time axis beneath it.
        let gx = w * 0.52
        let gRight = w - pad
        let axisH = barH * 0.12
        let gRect = CGRect(x: gx, y: insetY + axisH + gap, width: gRight - gx,
                           height: barH - insetY * 2 - axisH - gap)
        layer.addSublayer(graphLayer(rect: gRect, series: snap.series, color: zone,
                                     lineWidth: max(2, unit * 0.004), fill: true, dot: true,
                                     duration: duration))
        bar.addSublayer(text("0:00", fontSize: axisH * 0.78, weight: .regular, mono: true,
                             color: UIColor.white.withAlphaComponent(0.5),
                             frame: CGRect(x: gx, y: insetY, width: w * 0.2, height: axisH)))
        bar.addSublayer(text(clock(snap.durationSeconds), fontSize: axisH * 0.78, weight: .regular, mono: true,
                             color: UIColor.white.withAlphaComponent(0.5), align: .right,
                             frame: CGRect(x: gRight - w * 0.2, y: insetY, width: w * 0.2, height: axisH)))
    }

    // MARK: Reusable layer builders

    /// A frosted, rounded card with an optional border and soft shadow.
    private static func card(_ frame: CGRect, radius: CGFloat, fill: UIColor, alpha: CGFloat,
                             border: UIColor?, shadow: Bool = true) -> CALayer {
        let c = CALayer()
        c.frame = frame
        c.backgroundColor = fill.withAlphaComponent(alpha).cgColor
        c.cornerRadius = radius
        c.masksToBounds = false
        if let border {
            c.borderColor = border.cgColor
            c.borderWidth = max(1, frame.height * 0.014)
        }
        if shadow {
            c.shadowColor = UIColor.black.cgColor
            c.shadowOpacity = 0.35
            c.shadowRadius = radius * 0.9
            c.shadowOffset = CGSize(width: 0, height: -frame.height * 0.05)
        }
        return c
    }

    /// An HR line graph with a gradient area fill and a glowing dot that rides
    /// the actual curve (keyframe animation along the line path).
    private static func graphLayer(rect: CGRect, series: [Double], color: UIColor,
                                   lineWidth: CGFloat, fill: Bool, dot: Bool,
                                   duration: Double) -> CALayer {
        let container = CALayer()
        container.frame = rect
        guard series.count > 1 else { return container }

        let lo = (series.min() ?? 60) - 4
        let hi = (series.max() ?? 200) + 4
        let span = max(1, hi - lo)
        let n = series.count
        func point(_ i: Int) -> CGPoint {
            CGPoint(x: rect.width * CGFloat(i) / CGFloat(n - 1),
                    y: rect.height * CGFloat((series[i] - lo) / span))
        }

        let line = CGMutablePath()
        line.move(to: point(0))
        for i in 1..<n { line.addLine(to: point(i)) }

        if fill {
            let area = line.mutableCopy()!
            area.addLine(to: CGPoint(x: rect.width, y: 0))
            area.addLine(to: CGPoint(x: 0, y: 0))
            area.closeSubpath()
            let mask = CAShapeLayer()
            mask.path = area
            let grad = CAGradientLayer()
            grad.frame = container.bounds
            grad.colors = [color.withAlphaComponent(0.0).cgColor,
                           color.withAlphaComponent(0.42).cgColor]
            grad.startPoint = CGPoint(x: 0.5, y: 0.0)   // baseline (transparent)
            grad.endPoint = CGPoint(x: 0.5, y: 1.0)     // peaks (tinted)
            grad.mask = mask
            container.addSublayer(grad)
        }

        let stroke = CAShapeLayer()
        stroke.path = line
        stroke.strokeColor = color.cgColor
        stroke.fillColor = UIColor.clear.cgColor
        stroke.lineWidth = lineWidth
        stroke.lineJoin = .round
        stroke.lineCap = .round
        stroke.shadowColor = color.cgColor
        stroke.shadowRadius = lineWidth * 1.6
        stroke.shadowOpacity = 0.7
        stroke.shadowOffset = .zero
        container.addSublayer(stroke)

        if dot {
            let r = max(lineWidth * 2.2, rect.height * 0.06)
            let head = CALayer()
            head.frame = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
            head.cornerRadius = r
            head.backgroundColor = UIColor.white.cgColor
            head.borderColor = color.cgColor
            head.borderWidth = max(1.5, r * 0.34)
            head.shadowColor = color.cgColor
            head.shadowRadius = r * 1.1
            head.shadowOpacity = 0.95
            head.shadowOffset = .zero
            // Ride the curve on a uniform-time cadence (one data point per equal
            // time slice) so the dot stays in lock-step with the live bpm number.
            let ride = CAKeyframeAnimation(keyPath: "position")
            ride.values = (0..<n).map { NSValue(cgPoint: point($0)) }
            ride.keyTimes = (0..<n).map { NSNumber(value: Double($0) / Double(n - 1)) }
            ride.calculationMode = .linear
            ride.duration = max(0.1, duration)
            ride.beginTime = AVCoreAnimationBeginTimeAtZero
            ride.isRemovedOnCompletion = false
            ride.fillMode = .both
            head.add(ride, forKey: "ride")
            container.addSublayer(head)
        }
        return container
    }

    /// A big numeral that animates live through the HR `series`, synced to
    /// playback. AVVideoCompositionCoreAnimationTool does NOT honour a keyframe
    /// animation on a CATextLayer's `string` in an offline render (the number
    /// stays frozen on the burned-in video even though it ticks correctly during
    /// live recording). The reliable approach is to pre-render each bpm value to
    /// an image and animate a plain CALayer's `contents` with discrete keyframes
    /// — `contents` IS honoured offline. The cadence matches the dot riding the
    /// graph curve so the number and dot move together.
    private static func liveNumber(series: [Double], fallback: Int, fontSize: CGFloat,
                                   weight: UIFont.Weight, color: UIColor,
                                   align: NSTextAlignment = .left, frame: CGRect,
                                   duration: Double) -> CALayer {
        // Rounded system face, matching the rest of the big numerals.
        let font: UIFont
        if let d = UIFont.systemFont(ofSize: fontSize, weight: weight).fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: d, size: fontSize)
        } else {
            font = .systemFont(ofSize: fontSize, weight: weight)
        }
        let para = NSMutableParagraphStyle()
        para.alignment = align

        let lineH = fontSize * 1.3
        let imgSize = CGSize(width: max(1, frame.width), height: lineH)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.opaque = false
        fmt.scale = 3
        let renderer = UIGraphicsImageRenderer(size: imgSize, format: fmt)

        // Render one bpm value to a CGImage, cached by integer value so a long
        // clip that revisits the same bpm doesn't re-rasterise it.
        var cache: [Int: CGImage] = [:]
        func image(_ bpm: Int) -> CGImage? {
            if let cached = cache[bpm] { return cached }
            let img = renderer.image { _ in
                let attr = NSAttributedString(string: "\(bpm)", attributes: [
                    .font: font, .foregroundColor: color, .paragraphStyle: para,
                ])
                // Vertically centre the glyphs within the line box; paragraph
                // alignment handles horizontal placement across the full width.
                let textH = attr.size().height
                attr.draw(in: CGRect(x: 0, y: (lineH - textH) / 2, width: imgSize.width, height: textH))
            }
            let cg = img.cgImage
            if let cg { cache[bpm] = cg }
            return cg
        }

        let layer = CALayer()
        layer.contentsScale = 3
        layer.frame = CGRect(x: frame.minX, y: frame.midY - lineH / 2, width: frame.width, height: lineH)
        layer.contents = image(fallback)

        guard series.count > 1, duration > 0.05 else { return layer }

        // Cap the number of discrete steps so we don't rasterise thousands of
        // frames for a long clip; the eye can't track faster anyway.
        let maxSteps = 240
        let count = min(series.count, maxSteps)
        var values: [CGImage] = []
        var keyTimes: [NSNumber] = []
        for step in 0..<count {
            let idx = Int((Double(step) / Double(count - 1)) * Double(series.count - 1))
            let bpm = Int(series[idx].rounded())
            guard let cg = image(bpm) else { continue }
            values.append(cg)
            keyTimes.append(NSNumber(value: Double(step) / Double(count - 1)))
        }
        guard values.count > 1 else { return layer }

        let anim = CAKeyframeAnimation(keyPath: "contents")
        anim.values = values
        anim.keyTimes = keyTimes
        anim.calculationMode = .discrete
        anim.duration = duration
        anim.beginTime = AVCoreAnimationBeginTimeAtZero
        anim.isRemovedOnCompletion = false
        anim.fillMode = .both
        layer.add(anim, forKey: "live")
        // Seed the first frame so the very first composited frame isn't the peak.
        layer.contents = values.first
        return layer
    }

    /// A single line of text, vertically centred in `frame`. Defaults to the
    /// rounded system face for big numerals; pass `mono` for label rows.
    private static func text(_ string: String, fontSize: CGFloat, weight: UIFont.Weight,
                             mono: Bool = false, rounded: Bool = false, color: UIColor,
                             tracking: CGFloat = 0, align: NSTextAlignment = .left,
                             frame: CGRect) -> CATextLayer {
        let font: UIFont
        if mono {
            font = .monospacedSystemFont(ofSize: fontSize, weight: weight)
        } else if rounded,
                  let d = UIFont.systemFont(ofSize: fontSize, weight: weight).fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: d, size: fontSize)
        } else {
            font = .systemFont(ofSize: fontSize, weight: weight)
        }
        let para = NSMutableParagraphStyle()
        para.alignment = align
        let attr = NSAttributedString(string: string, attributes: [
            .font: font, .foregroundColor: color, .kern: tracking, .paragraphStyle: para,
        ])
        let t = CATextLayer()
        t.string = attr
        t.contentsScale = 3
        t.isWrapped = false
        t.truncationMode = .none
        let lineH = fontSize * 1.3
        t.frame = CGRect(x: frame.minX, y: frame.midY - lineH / 2, width: frame.width, height: lineH)
        return t
    }

    /// hex 0xRRGGBB → UIColor.
    private static func ui(_ hex: UInt32, _ a: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: a)
    }

    /// Colour of the zone a given bpm falls in (matches the app's RC.zones).
    private static func zoneColor(_ bpm: Int, _ maxHR: Int) -> UIColor {
        let hexes: [UInt32] = [0x4C7DF0, 0x25B69E, 0xE7C24A, 0xF0883C, 0xFF4B3A]
        return ui(hexes[min(max(HRZone.index(bpm, max: Double(maxHR)), 0), 4)])
    }

    /// m:ss clock for the duration label.
    private static func clock(_ secs: Int) -> String {
        String(format: "%d:%02d", secs / 60, secs % 60)
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
