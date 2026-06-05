import SwiftUI

struct TimerSetupView: View {
    @Environment(Router.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(HeartRateMonitor.self) private var hr

    @State private var round = 300
    @State private var rest = 60
    @State private var rounds = 3

    private var total: Int { round * rounds + rest * max(0, rounds - 1) }

    private var blocks: [(key: String, flex: Int)] {
        var out: [(String, Int)] = []
        for i in 0..<rounds {
            out.append(("R\(i + 1)", round))
            if i < rounds - 1 { out.append(("rest", rest)) }
        }
        return out
    }

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(eyebrow: "Before you record", onBack: { router.pop() })

                VStack(alignment: .leading, spacing: 16) {
                    Text("Round timer")
                        .font(RC.display(30, .bold))
                        .foregroundStyle(RC.text)

                    VStack(spacing: 10) {
                        Stepper2(label: "Round length", sub: "work interval", value: Session.clock(round),
                                 onDec: { round = max(60, round - 30) }, onInc: { round += 30 })
                        Stepper2(label: "Rest", sub: "between rounds", value: Session.clock(rest),
                                 onDec: { rest = max(0, rest - 15) }, onInc: { rest += 15 })
                        Stepper2(label: "Rounds", sub: "total", value: "\(rounds)",
                                 onDec: { rounds = max(1, rounds - 1) }, onInc: { rounds += 1 })
                    }

                    // Structure preview
                    VStack(spacing: 0) {
                        HStack {
                            Eyebrow("Session structure")
                            Spacer()
                            Text("\(Session.clock(total)) total").font(RC.mono(11)).foregroundStyle(RC.text2)
                        }
                        .padding(.bottom, 12)
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(b.key == "rest" ? Color.clear : RC.hr.opacity(0.92))
                                        .frame(height: 26)
                                        .overlay {
                                            if b.key == "rest" {
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .strokeBorder(RC.line2, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                            }
                                        }
                                    Text(b.key)
                                        .font(RC.mono(9))
                                        .foregroundStyle(b.key == "rest" ? RC.text3 : RC.text2)
                                }
                                .frame(maxWidth: .infinity)
                                .layoutPriority(Double(b.flex))
                            }
                        }
                    }
                    .rcCard(16)

                    // Camera lens picker — remembered as the default launch lens.
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Camera").font(.system(size: 15, weight: .semibold)).foregroundStyle(RC.text)
                            Text("flip anytime while recording").font(RC.mono(10.5)).foregroundStyle(RC.text3)
                        }
                        Spacer()
                        Segmented(options: [
                            SegmentOption(value: "rear", label: "REAR"),
                            SegmentOption(value: "front", label: "FRONT"),
                        ], selection: Binding(
                            get: { settings.frontCamera ? "front" : "rear" },
                            set: { settings.frontCamera = $0 == "front" }))
                        .frame(width: 168)
                    }
                    .rcCard(16)

                    // Voice countdown toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Voice countdown").font(.system(size: 15, weight: .semibold)).foregroundStyle(RC.text)
                            Text("earpiece only · won't hit video mic").font(RC.mono(10.5)).foregroundStyle(RC.text3)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.voiceCountdown).labelsHidden().tint(RC.hr)
                    }
                    .rcCard(16)

                    // HR source row
                    HStack(spacing: 11) {
                        Image(systemName: "wave.3.right").font(.system(size: 17)).foregroundStyle(RC.z1)
                        Text(hr.deviceName ?? (settings.hrSource == .bluetooth ? "No strap linked" : "Simulated source"))
                            .font(.system(size: 13)).foregroundStyle(RC.text)
                        Spacer()
                        Text(hr.isConnected
                             ? "connected"
                             : (settings.hrSource == .bluetooth ? "pair in Settings" : "ready"))
                            .font(RC.mono(10.5))
                            .foregroundStyle(hr.isConnected ? RC.good : RC.text3)
                    }
                    .rcCard2(14)

                    Button {
                        router.push(.record(round: round, rest: rest, rounds: rounds))
                    } label: {
                        Label("Start recording", systemImage: "video.fill")
                    }
                    .buttonStyle(RCButtonStyle(kind: .hr))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Stepper row

struct Stepper2: View {
    var label: String
    var sub: String
    var value: String
    var onDec: () -> Void
    var onInc: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 15, weight: .semibold)).foregroundStyle(RC.text)
                Text(sub).font(RC.mono(10.5)).foregroundStyle(RC.text3)
            }
            Spacer()
            HStack(spacing: 14) {
                circleButton("minus", action: onDec)
                Text(value).font(RC.mono(21, .semibold)).foregroundStyle(RC.text)
                    .frame(minWidth: 56)
                circleButton("plus", action: onInc)
            }
        }
        .rcCard(16)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(RC.text)
                .frame(width: 34, height: 34)
                .background(RC.surface2, in: Circle())
                .overlay(Circle().strokeBorder(RC.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
