import SwiftUI

// Heart-rate line graph. Custom-drawn (rather than Swift Charts) so markers
// and the draggable playhead align exactly with the curve — a direct port of
// the prototype's smoothPath() Catmull-Rom interpolation (proto/ui.jsx).
struct HRGraph: View {
    var series: [Double]
    var minY: Double = 120
    var maxY: Double = 198
    var stroke: Color = RC.hr
    var area: Color = RC.hr
    var fill: Bool = true
    var grid: Bool = true
    var markers: [Double] = []          // positions 0...1
    var playhead: Double? = nil         // position 0...1
    var lineWidth: CGFloat = 2.4
    var faint: Bool = false
    var padTop: CGFloat = 10
    var padBot: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pts = points(w: w, h: h)

            ZStack(alignment: .topLeading) {
                if grid {
                    ForEach([0.5, 1.0], id: \.self) { b in
                        let y = padTop + b * (h - padTop - padBot)
                        Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
                            .stroke(RC.line, lineWidth: 1)
                    }
                }

                if fill, pts.count > 1 {
                    areaPath(pts, w: w, h: h)
                        .fill(LinearGradient(
                            colors: [area.opacity(faint ? 0.14 : 0.26), area.opacity(0)],
                            startPoint: .top, endPoint: .bottom))
                }

                if pts.count > 1 {
                    smoothPath(pts)
                        .stroke(faint ? RC.text3 : stroke,
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(markers.enumerated()), id: \.offset) { _, pos in
                    let x = pos * w
                    Path { p in
                        p.move(to: CGPoint(x: x, y: padTop - 4))
                        p.addLine(to: CGPoint(x: x, y: h - 2))
                    }
                    .stroke(RC.line2, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                    Circle()
                        .fill(RC.surface3)
                        .overlay(Circle().strokeBorder(RC.text2, lineWidth: 1.4))
                        .frame(width: 18, height: 18)
                        .position(x: x, y: padTop - 2)
                }

                if let ph = playhead, pts.count > 1 {
                    let idx = min(pts.count - 1, max(0, Int((ph * Double(pts.count - 1)).rounded())))
                    let x = ph * w
                    Path { p in
                        p.move(to: CGPoint(x: x, y: padTop - 4))
                        p.addLine(to: CGPoint(x: x, y: h))
                    }
                    .stroke(RC.text.opacity(0.8), lineWidth: 1.5)
                    Circle()
                        .fill(RC.hr)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .frame(width: 10, height: 10)
                        .position(x: x, y: pts[idx].y)
                }
            }
        }
    }

    // MARK: Geometry

    private func points(w: CGFloat, h: CGFloat) -> [CGPoint] {
        let n = series.count
        guard n > 1 else { return [] }
        return series.enumerated().map { i, v in
            let x = CGFloat(i) / CGFloat(n - 1) * w
            let t = max(0, min(1, (v - minY) / (maxY - minY)))
            let y = h - padBot - CGFloat(t) * (h - padTop - padBot)
            return CGPoint(x: x, y: y)
        }
    }

    private func smoothPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard pts.count > 1 else { return path }
        path.move(to: pts[0])
        for i in 0..<(pts.count - 1) {
            let p0 = i > 0 ? pts[i - 1] : pts[i]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = i + 2 < pts.count ? pts[i + 2] : p2
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }

    private func areaPath(_ pts: [CGPoint], w: CGFloat, h: CGFloat) -> Path {
        var path = smoothPath(pts)
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}
