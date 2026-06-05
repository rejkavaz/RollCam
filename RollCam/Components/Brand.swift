import SwiftUI

// MatPulse logo system — ported from the brand package (brand/logo.jsx).
// The mark is a heartbeat pulse inside a rounded "mat" tile; the central spike
// is exaggerated and capped with a record dot — record + heart rate + the mat,
// in one form. The wordmark splits "Mat" (ink) from "Pulse" (ember).

// MARK: - Pulse path

/// The shared heartbeat path, drawn in the design's 120×120 viewBox so the
/// geometry matches the app icon and brand book exactly:
/// `M20 67 H45 l5 -3 l6 12 l9 -42 l8 50 l6 -17 l4 0 H100`.
struct PulseShape: Shape {
    // Points resolved from the path's M/H (absolute) and l (relative) commands.
    private static let pts: [CGPoint] = [
        .init(x: 20, y: 67), .init(x: 45, y: 67), .init(x: 50, y: 64),
        .init(x: 56, y: 76), .init(x: 65, y: 34), .init(x: 73, y: 84),
        .init(x: 79, y: 67), .init(x: 83, y: 67), .init(x: 100, y: 67),
    ]
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 120
        var p = Path()
        for (i, pt) in Self.pts.enumerated() {
            let q = CGPoint(x: pt.x * s, y: pt.y * s)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        return p
    }
}

/// Apex of the tall spike, where the record dot sits (design units, 120 box).
private let pulsePeak = CGPoint(x: 68, y: 33)

// MARK: - Mark

enum MarkVariant { case color, knockout, monoLight, monoDark }

/// The MatPulse mark: a rounded mat tile holding the heartbeat pulse + record dot.
struct MatPulseMark: View {
    var size: CGFloat = 120
    var variant: MarkVariant = .color
    var dot: Bool = true

    private var stroke: CGFloat { size / 120 * 7 }

    private var tile: AnyShapeStyle {
        switch variant {
        case .color:
            return AnyShapeStyle(LinearGradient(colors: [RC.hr2, RC.hr],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .knockout:  return AnyShapeStyle(RC.hr)
        case .monoLight: return AnyShapeStyle(RC.text)
        case .monoDark:  return AnyShapeStyle(RC.bg)
        }
    }
    private var lineColor: Color {
        switch variant {
        case .color, .knockout: return .white
        case .monoLight:        return RC.bg
        case .monoDark:         return RC.text
        }
    }

    var body: some View {
        let s = size / 120
        ZStack {
            RoundedRectangle(cornerRadius: size * (34.0 / 120.0), style: .continuous)
                .fill(tile)
                .overlay(
                    RoundedRectangle(cornerRadius: size * (34.0 / 120.0), style: .continuous)
                        .strokeBorder(variant == .monoDark ? RC.line2 : .clear, lineWidth: 2)
                )
            PulseShape()
                .stroke(lineColor, style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
            if dot {
                Circle()
                    .fill(lineColor)
                    .frame(width: stroke * 1.9, height: stroke * 1.9)
                    .position(x: pulsePeak.x * s, y: pulsePeak.y * s)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wordmark

enum WordmarkVariant { case onDark, onLight, mono }

/// "Mat" in ink + "Pulse" in ember — the brand two-tone split.
struct MatPulseWordmark: View {
    var size: CGFloat = 38
    var variant: WordmarkVariant = .onDark

    private var matColor: Color { variant == .onLight ? RC.bg : RC.text }
    private var pulseColor: Color { variant == .mono ? matColor : RC.hr }

    var body: some View {
        (Text("Mat").foregroundColor(matColor) + Text("Pulse").foregroundColor(pulseColor))
            .font(.system(size: size, weight: .heavy, design: .default))
            .tracking(-size * 0.03)
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: - Lockups

/// Horizontal lockup: mark + wordmark.
struct MatPulseLockup: View {
    var markSize: CGFloat = 56
    var type: CGFloat = 30
    var variant: WordmarkVariant = .onDark

    var body: some View {
        HStack(spacing: markSize * 0.28) {
            MatPulseMark(size: markSize, variant: .color)
            MatPulseWordmark(size: type, variant: variant)
        }
    }
}

/// Vertical lockup: mark stacked over wordmark.
struct MatPulseLockupV: View {
    var markSize: CGFloat = 84
    var type: CGFloat = 30
    var variant: WordmarkVariant = .onDark

    var body: some View {
        VStack(spacing: markSize * 0.24) {
            MatPulseMark(size: markSize, variant: .color)
            MatPulseWordmark(size: type, variant: variant)
        }
    }
}

#Preview {
    ZStack {
        RC.bg.ignoresSafeArea()
        VStack(spacing: 28) {
            MatPulseLockup(markSize: 60, type: 38)
            MatPulseLockupV(markSize: 84, type: 30)
            HStack(spacing: 16) {
                MatPulseMark(size: 64, variant: .color)
                MatPulseMark(size: 64, variant: .knockout)
                MatPulseMark(size: 64, variant: .monoDark)
            }
            Text("Train by heart.")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(RC.text)
        }
    }
}
