import Foundation
import CoreBluetooth
import Observation

// Live heart-rate source. Two backends:
//   • .simulated — a deterministic wandering bpm, so the app is fully alive
//     in the simulator and without any hardware.
//   • .bluetooth — a real BLE chest strap exposing the standard Heart Rate
//     Service (0x180D / measurement 0x2A37): Polar H10, Wahoo TICKR,
//     Garmin HRM-Pro, etc. No special entitlement required.

enum HRSourceKind: String, CaseIterable, Identifiable {
    case simulated, bluetooth
    var id: String { rawValue }
    var label: String { self == .simulated ? "Simulated" : "Bluetooth strap" }
}

@Observable
final class HeartRateMonitor {
    var bpm: Int = 0
    var series: [Double] = []        // the live capture buffer for the current recording
    var isConnected: Bool = false
    var deviceName: String?
    var kind: HRSourceKind = .simulated

    // Cap the capture buffer generously so a very long session can't grow without
    // bound, while still keeping full resolution for any normal-length roll.
    private let maxSamples = 12_000
    private var base: Double = 178
    private var current: Double = 178
    private var timer: Timer?
    private var ble: BLEHeartRateClient?

    init() {}

    // MARK: Live connection (used by Settings to pair / preview before recording)

    /// Begin streaming from the selected source without clearing a recording.
    func connect() {
        switch kind {
        case .simulated: startSimulated()
        case .bluetooth: if ble == nil { startBluetooth() }
        }
    }

    /// Fully release the source and any paired strap.
    func disconnect() {
        timer?.invalidate(); timer = nil
        ble?.stop(); ble = nil
        isConnected = false
        deviceName = nil
        bpm = 0
    }

    // MARK: Recording control

    /// Start (or continue) a live source and reset the capture buffer so the saved
    /// series contains only samples from this recording.
    func start(base: Double = 178) {
        self.base = base
        self.current = base
        series = []
        switch kind {
        case .simulated:
            ble?.stop(); ble = nil
            startSimulated()
        case .bluetooth:
            timer?.invalidate(); timer = nil
            if ble == nil { startBluetooth() }   // reuse a strap already paired in Settings
        }
    }

    /// End the recording. A simulated source is stopped; a real strap is left
    /// connected so it's ready for the next recording (use `disconnect()` to release).
    func stop() {
        timer?.invalidate(); timer = nil
    }

    func push(_ value: Double) {
        let v = min(220, max(40, value))
        bpm = Int(v.rounded())
        series.append(v)
        if series.count > maxSamples { series.removeFirst(series.count - maxSamples) }
    }

    // MARK: Simulated

    private func startSimulated() {
        isConnected = true
        deviceName = "Simulated"
        current = base
        bpm = Int(base.rounded())
        timer?.invalidate()
        // Schedule in `.common` modes (not just `.default`): while recording the
        // main run loop sits in a mode that starves default-mode timers, which
        // froze the simulated HR mid-roll even though the clock kept ticking.
        let t = Timer(timeInterval: 0.9, repeats: true) { [weak self] _ in
            guard let self else { return }
            let drift = (self.base - self.current) * 0.08
            self.current = min(198, max(120, self.current + drift + Double.random(in: -4.5...4.5)))
            self.push(self.current)
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: Bluetooth

    private func startBluetooth() {
        let client = BLEHeartRateClient()
        client.onValue = { [weak self] v in self?.push(Double(v)) }
        client.onState = { [weak self] name, connected in
            self?.deviceName = name
            self?.isConnected = connected
            if !connected { self?.bpm = 0 }
        }
        client.start()
        ble = client
    }
}

// MARK: - CoreBluetooth client (NSObject kept separate from the @Observable monitor)

final class BLEHeartRateClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var onValue: ((Int) -> Void)?
    var onState: ((String?, Bool) -> Void)?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?

    private let hrService = CBUUID(string: "180D")
    private let hrMeasurement = CBUUID(string: "2A37")

    func start() {
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func stop() {
        if let p = peripheral { central?.cancelPeripheralConnection(p) }
        central?.stopScan()
        central = nil
        peripheral = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [hrService], options: nil)
        } else {
            onState?(nil, false)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onState?(peripheral.name, true)
        peripheral.discoverServices([hrService])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        onState?(peripheral.name, false)
        central.scanForPeripherals(withServices: [hrService], options: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == hrService {
            peripheral.discoverCharacteristics([hrMeasurement], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics ?? [] where c.uuid == hrMeasurement {
            peripheral.setNotifyValue(true, for: c)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == hrMeasurement, let data = characteristic.value, let bpm = Self.parseHR(data) else { return }
        onValue?(bpm)
    }

    /// Parse a Heart Rate Measurement (0x2A37) packet per the BLE spec.
    static func parseHR(_ data: Data) -> Int? {
        guard let flags = data.first else { return nil }
        let is16Bit = (flags & 0x01) != 0
        if is16Bit {
            guard data.count >= 3 else { return nil }
            return Int(data[1]) | (Int(data[2]) << 8)
        } else {
            guard data.count >= 2 else { return nil }
            return Int(data[1])
        }
    }
}
