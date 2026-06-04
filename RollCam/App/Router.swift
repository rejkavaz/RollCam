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
@Observable
final class AppSettings {
    var voiceCountdown: Bool = true
    var blurFaces: Bool = true
    var hrSource: HRSourceKind = .simulated
    var maxHR: Int = 195
}
