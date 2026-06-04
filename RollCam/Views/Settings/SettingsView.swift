import SwiftUI

struct SettingsView: View {
    @Environment(Router.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(HeartRateMonitor.self) private var hr

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RCHeader(title: "Settings", eyebrow: "RollCam", large: true, onBack: { router.pop() })

                VStack(alignment: .leading, spacing: 16) {
                    // Heart-rate source
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Heart-rate source")
                        Segmented(options: HRSourceKind.allCases.map {
                            SegmentOption(value: $0.rawValue, label: $0.label.uppercased())
                        }, selection: Binding(
                            get: { settings.hrSource.rawValue },
                            set: { settings.hrSource = HRSourceKind(rawValue: $0) ?? .simulated; hr.kind = settings.hrSource }))
                        HStack(spacing: 11) {
                            Image(systemName: "wave.3.right").font(.system(size: 17)).foregroundStyle(RC.z1)
                            Text(hr.deviceName ?? "No strap linked").font(.system(size: 13)).foregroundStyle(RC.text)
                            Spacer()
                            Text(hr.isConnected ? "connected" : "idle")
                                .font(RC.mono(10.5)).foregroundStyle(hr.isConnected ? RC.good : RC.text3)
                        }
                        .rcCard2(14)
                        Text("Works with any standard Bluetooth chest strap (Polar H10, Wahoo TICKR, Garmin HRM) exposing the 0x180D heart-rate service. No account, no pairing code.")
                            .font(.system(size: 12)).foregroundStyle(RC.text3).lineSpacing(3)
                    }

                    // Max HR stepper
                    Stepper2(label: "Max heart rate", sub: "used for zone thresholds", value: "\(settings.maxHR)",
                             onDec: { settings.maxHR = max(120, settings.maxHR - 1) },
                             onInc: { settings.maxHR = min(220, settings.maxHR + 1) })

                    // Voice countdown
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Voice countdown").font(.system(size: 15, weight: .semibold)).foregroundStyle(RC.text)
                            Text("earpiece only · won't hit video mic").font(RC.mono(10.5)).foregroundStyle(RC.text3)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.voiceCountdown).labelsHidden().tint(RC.hr)
                    }
                    .rcCard(16)

                    // Privacy
                    Eyebrow("Privacy")
                    VStack(alignment: .leading, spacing: 10) {
                        infoRow("lock.shield", "All local", "Sessions, video and HR data never leave the device. No account, no cloud, no AI.")
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Blur partners' faces").font(.system(size: 15, weight: .semibold)).foregroundStyle(RC.text)
                                Text("on-device, before any export").font(RC.mono(10.5)).foregroundStyle(RC.text3)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.blurFaces).labelsHidden().tint(RC.good)
                        }
                        .rcCard(16)
                    }

                    // Data export
                    Eyebrow("Your data")
                    infoRow("square.and.arrow.up", "Open CSV export", "Every session's HR series exports as plain CSV from its share screen — your data is yours.")

                    // About
                    Eyebrow("About")
                    infoRow("heart.fill", "RollCam", "Open-source performance instrument for grapplers. No subscriptions, no AI, no telemetry.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func infoRow(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 17)).foregroundStyle(RC.hr)
                .frame(width: 34, height: 34)
                .background(RC.hrDim, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(RC.text)
                Text(body).font(.system(size: 12)).foregroundStyle(RC.text3).lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .rcCard2(14)
    }
}
