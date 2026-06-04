import SwiftUI

// MARK: - Screen header (large title, optional back + eyebrow + trailing)

struct RCHeader<Right: View>: View {
    var title: String? = nil
    var eyebrow: String? = nil
    var large: Bool = false
    var onBack: (() -> Void)? = nil
    @ViewBuilder var right: Right

    var body: some View {
        VStack(alignment: .leading, spacing: large ? 10 : 6) {
            HStack(alignment: .center) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(RC.text)
                            .frame(width: 36, height: 36)
                            .background(RC.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(RC.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }

                Spacer()
                if let eyebrow, !large { Eyebrow(eyebrow); Spacer() }
                right
            }
            .frame(minHeight: 28)

            if large, let eyebrow { Eyebrow(eyebrow) }
            if let title {
                Text(title)
                    .font(RC.display(30, .bold))
                    .foregroundStyle(RC.text)
            }
        }
        .padding(.top, 56)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
}

extension RCHeader where Right == EmptyView {
    init(title: String? = nil, eyebrow: String? = nil, large: Bool = false, onBack: (() -> Void)? = nil) {
        self.title = title; self.eyebrow = eyebrow; self.large = large
        self.onBack = onBack; self.right = EmptyView()
    }
}

// MARK: - Bottom tab bar with center REC button

enum RootTab: String { case rolls, stats }

struct RCTabBar: View {
    @Binding var active: RootTab
    var onRec: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tab(.rolls, system: "list.bullet", label: "ROLLS")

            Button(action: onRec) {
                Image(systemName: "video.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(RC.hr, in: Circle())
                    .overlay(Circle().strokeBorder(RC.bg, lineWidth: 4))
                    .shadow(color: RC.hr.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .offset(y: -22)
            .frame(width: 60)

            tab(.stats, system: "chart.bar.fill", label: "STATS")
        }
        .padding(.top, 10)
        .padding(.bottom, 26)
        .background(
            LinearGradient(colors: [RC.bg, RC.bg, .clear], startPoint: .bottom, endPoint: .top)
        )
        .overlay(Rectangle().fill(RC.line).frame(height: 1), alignment: .top)
    }

    private func tab(_ t: RootTab, system: String, label: String) -> some View {
        Button { active = t } label: {
            VStack(spacing: 5) {
                Image(systemName: system)
                    .font(.system(size: 22, weight: active == t ? .semibold : .regular))
                Text(label).font(RC.mono(9)).tracking(0.8)
            }
            .foregroundStyle(active == t ? RC.text : RC.text3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cinematic camera-style background (fallback when no live camera)

struct CinematicBackground: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x283041), Color(hex: 0x11151D), Color(hex: 0x070A0E)],
                center: UnitPoint(x: 0.5, y: 0.35), startRadius: 0, endRadius: 460)
            Ellipse()
                .fill(Color.white.opacity(0.03))
                .frame(width: 150, height: 110)
                .blur(radius: 20)
            // vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: UnitPoint(x: 0.5, y: 0.4), startRadius: 120, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}
