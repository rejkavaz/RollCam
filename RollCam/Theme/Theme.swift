import SwiftUI

// Design tokens ported from the RollCam prototype (proto/theme.css).
// "Performance instrument for fighters": near-black cinematic surfaces,
// a single ember-red heart-rate accent, a cool->hot zone ramp used only
// for HR, geometric display type with monospaced numerals.

enum RC {

    // MARK: Surfaces
    static let bg       = Color(hex: 0x0A0C10)
    static let bg2      = Color(hex: 0x0E1116)
    static let surface  = Color(hex: 0x15181F)
    static let surface2 = Color(hex: 0x1B1F28)
    static let surface3 = Color(hex: 0x232834)
    static let line     = Color.white.opacity(0.07)
    static let line2    = Color.white.opacity(0.13)

    // MARK: Text
    static let text  = Color(hex: 0xF3F5F9)
    static let text2 = Color(hex: 0x9BA4B4)
    static let text3 = Color(hex: 0x626B7B)

    // MARK: Heart-rate accent
    static let hr    = Color(hex: 0xFF4B3A)
    static let hr2   = Color(hex: 0xFF6B52)
    static let hrDim = Color(hex: 0xFF4B3A).opacity(0.16)

    // MARK: HR zone ramp (cool -> hot)
    static let z1 = Color(hex: 0x4C7DF0)
    static let z2 = Color(hex: 0x25B69E)
    static let z3 = Color(hex: 0xE7C24A)
    static let z4 = Color(hex: 0xF0883C)
    static let z5 = Color(hex: 0xFF4B3A)
    static let zones: [Color] = [z1, z2, z3, z4, z5]

    static let good = Color(hex: 0x38D39F)

    // MARK: Type
    // The prototype used Sora + JetBrains Mono. To keep the sideload build
    // self-contained (no bundled font files), we use the system geometric
    // face for display and the monospaced face for numerals — same intent,
    // zero binary assets. Swap to custom fonts here if ever desired.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Background gradient used behind the device content.
    static var appBackground: some View {
        ZStack {
            bg
            RadialGradient(
                colors: [Color(hex: 0x14181F), bg],
                center: .top, startRadius: 0, endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hex color

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Reusable surface styles

extension View {
    /// Primary card surface (r:18).
    func rcCard(_ padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .background(RC.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(RC.line, lineWidth: 1)
            )
    }

    /// Secondary card surface (r:16).
    func rcCard2(_ padding: CGFloat = 14) -> some View {
        self.padding(padding)
            .background(RC.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RC.line, lineWidth: 1)
            )
    }
}

// MARK: - Eyebrow label

struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(RC.mono(10, .semibold))
            .tracking(1.8)
            .foregroundStyle(RC.text3)
    }
}

// MARK: - Buttons

enum RCButtonKind { case primary, hr, ghost, soft }

struct RCButtonStyle: ButtonStyle {
    var kind: RCButtonKind = .hr
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RC.display(15, .semibold))
            .frame(maxWidth: .infinity)
            .padding(16)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
            .shadow(color: kind == .hr ? RC.hr.opacity(0.34) : .clear, radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Color(hex: 0x0A0C10)
        case .hr:      return .white
        case .ghost:   return RC.text
        case .soft:    return RC.text
        }
    }
    private var background: Color {
        switch kind {
        case .primary: return RC.text
        case .hr:      return RC.hr
        case .ghost:   return .clear
        case .soft:    return RC.surface2
        }
    }
    private var border: Color {
        switch kind {
        case .ghost: return RC.line2
        case .soft:  return RC.line
        default:     return .clear
        }
    }
}
