import SwiftUI

// MARK: - Zone distribution bar

struct ZoneBar: View {
    var dist: [Int]
    var height: CGFloat = 10
    var labels: Bool = false

    var body: some View {
        let total = max(1, dist.reduce(0, +))
        VStack(spacing: 8) {
            GeometryReader { geo in
                let gaps = CGFloat(max(0, dist.filter { $0 > 0 }.count - 1)) * 3
                let usable = max(0, geo.size.width - gaps)
                HStack(spacing: 3) {
                    ForEach(Array(dist.enumerated()), id: \.offset) { i, v in
                        if v > 0 {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(HRZone.color(i))
                                .opacity(i >= 3 ? 1 : 0.85)
                                .frame(width: usable * CGFloat(v) / CGFloat(total))
                        }
                    }
                }
            }
            .frame(height: height)

            if labels {
                HStack {
                    ForEach(0..<5, id: \.self) { i in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2).fill(HRZone.color(i)).frame(width: 8, height: 8)
                            Text("Z\(i + 1)").font(RC.mono(9)).foregroundStyle(RC.text3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    var label: String
    var value: String
    var unit: String? = nil
    var accent: Bool = false
    var trend: String? = nil
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Eyebrow(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(RC.mono(26, .semibold))
                    .foregroundStyle(accent ? RC.hr : RC.text)
                if let unit { Text(unit).font(RC.mono(11)).foregroundStyle(RC.text3) }
            }
            if let trend {
                Text(trend).font(RC.mono(10.5)).foregroundStyle(RC.good)
            } else if let sub {
                Text(sub).font(RC.mono(10.5)).foregroundStyle(RC.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rcCard2(14)
    }
}

// MARK: - Segmented control

struct SegmentOption: Identifiable {
    let value: String
    let label: String
    var id: String { value }
}

struct Segmented: View {
    let options: [SegmentOption]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options) { opt in
                let on = selection == opt.value
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = opt.value }
                } label: {
                    Text(opt.label)
                        .font(RC.mono(11.5, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(on ? RC.text : RC.text3)
                        .background(on ? RC.surface3 : .clear,
                                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RC.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
    }
}

// MARK: - Chip / pill

struct Chip: View {
    let label: String
    var selected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12.5, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Color(hex: 0x0A0C10) : RC.text2)
                .padding(.vertical, 7).padding(.horizontal, 13)
                .background(selected ? RC.text : .clear, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? RC.text : RC.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon button (36x36 rounded surface)

struct IconButton: View {
    let systemName: String
    var active: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(active ? Color(hex: 0x0A0C10) : RC.text)
                .frame(width: 36, height: 36)
                .background(active ? RC.text : RC.surface2,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header (eyebrow + optional trailing)

struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Eyebrow(title)
            Spacer()
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) { self.title = title; self.trailing = EmptyView() }
}
