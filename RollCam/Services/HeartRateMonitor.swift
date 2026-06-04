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
    var bpm: Int = 172
    var series: [Double] = []
    var isConnected: Bool = false
    var deviceName: String?
    var kind: HRSourceKind = .simulated

    private let windowLength = 48
    private var base: Double = 172
    private var current: Double = 172
    private var timer: Timer?
    private var ble: BLEHeartRateClient?

    init() {
        series = (0..<windowLength).map { i in
            base + sin(Double(i) / 5) * 11 + Double.random(in: -3...3)
        }
    }

    // MARK: Control

    func start(base: Double = 172) {
        self.base = base
        self.current = base
        switch kind {
        case .simulated: startSimulated()
        case .bluetooth: startBluetooth()
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        ble?.stop()
        isConnected = false
    }

    func push(_ value: Double) {
        let v = min(198, max(120, value))
        bpm = Int(v.rounded())
        series.append(v)
        if series.count > windowLength { series.removeFirst(series.count - windowLength) }
    }

    // MARK: Simulated

    private func startSimulated() {
        isConnected = true
        deviceName = "Simulated"
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] _ in
            guard let self else { return }
            let drift = (self.base - self.current) * 0.08
            self.current = min(198, max(120, self.current + drift + Double.random(in: -4.5...4.5)))
            self.push(self.current)
        }
    }

    // MARK: Bluetooth

    private func startBluetooth() {
        let client = BLEHeartRateClient()
        client.onValue = { [weak self] v in self?.push(Double(v)) }
        client.onState = { [weak self] name, connected in
            self?.deviceName = name
            self?.isConnected = connected
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
