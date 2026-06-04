import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var context
    @State private var tab: RootTab = .rolls

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                RC.appBackground
                Group {
                    switch tab {
                    case .rolls: LibraryView()
                    case .stats: DashboardView()
                    }
                }
                RCTabBar(active: $tab, onRec: { router.push(.timer) })
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .timer:
            TimerSetupView().rcScreen()
        case let .record(round, rest, rounds):
            LiveRecordingView(roundLength: round, rest: rest, rounds: rounds)
                .rcScreen()
        case let .post(id, fresh):
            loaded(id) { PostSessionView(session: $0, fresh: fresh) }
        case let .reviewTag(id):
            loaded(id) { ReviewTagView(session: $0) }
        case let .compare(id):
            loaded(id) { RoundCompareView(session: $0) }
        case let .export(id):
            loaded(id) { ExportView(session: $0) }
        case .settings:
            SettingsView().rcScreen()
        }
    }

    @ViewBuilder
    private func loaded<Content: View>(_ id: UUID, @ViewBuilder content: (Session) -> Content) -> some View {
        if let session = session(for: id) {
            content(session).rcScreen()
        } else {
            Text("Session not found")
                .foregroundStyle(RC.text2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rcScreen()
        }
    }

    private func session(for id: UUID) -> Session? {
        let descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}

extension View {
    /// Common chrome for a pushed screen: cinematic background, hidden nav bar.
    func rcScreen() -> some View {
        self
            .background(RC.appBackground)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}
