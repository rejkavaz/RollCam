import SwiftUI
import Observation

// Navigation routes pushed onto the NavigationStack. Sessions are referenced
// by id and re-fetched in each destination, so routes stay value types.
enum Route: Hashable {
    case timer
    case record(round: Int, rest: Int, rounds: Int)
    case post(id: UUID, fresh: Bool)
    case reviewTag(id: UUID)
    case compare(id: UUID)
    case export(id: UUID)
    case settings
}

@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeAll() }

    /// Replace the whole stack — used after Stop so "back" from the post-session
    /// screen returns to the tab root rather than the live recording screen.
    func reset(to route: Route) { path = [route] }
}

// App-wide preferences (no AI, no account, all local).
// Persisted to UserDefaults so they survive relaunch.
@Observable
final class AppSettings {
    var voiceCountdown: Bool { didSet { store.set(voiceCountdown, forKey: Keys.voiceCountdown) } }
    var blurFaces: Bool { didSet { store.set(blurFaces, forKey: Keys.blurFaces) } }
    var hrSource: HRSourceKind { didSet { store.set(hrSource.rawValue, forKey: Keys.hrSource) } }
    var maxHR: Int { didSet { store.set(maxHR, forKey: Keys.maxHR) } }
    // Preferred lens to launch the recorder on; the Flip button still overrides
    // it mid-roll. Remembered so the athlete's usual angle is the default.
    var frontCamera: Bool { didSet { store.set(frontCamera, forKey: Keys.frontCamera) } }

    @ObservationIgnored private let store = UserDefaults.standard

    private enum Keys {
        static let voiceCountdown = "settings.voiceCountdown"
        static let blurFaces = "settings.blurFaces"
        static let hrSource = "settings.hrSource"
        static let maxHR = "settings.maxHR"
        static let frontCamera = "settings.frontCamera"
    }

    init() {
        // `object(forKey:)` lets us distinguish "never set" from "set to false".
        voiceCountdown = store.object(forKey: Keys.voiceCountdown) as? Bool ?? true
        blurFaces = store.object(forKey: Keys.blurFaces) as? Bool ?? true
        hrSource = HRSourceKind(rawValue: store.string(forKey: Keys.hrSource) ?? "") ?? .simulated
        let savedMax = store.integer(forKey: Keys.maxHR)
        maxHR = savedMax == 0 ? 195 : savedMax
        frontCamera = store.object(forKey: Keys.frontCamera) as? Bool ?? false
    }
}
