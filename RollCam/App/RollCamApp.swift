import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.rejkavaz.RollCam", category: "Startup")

@main
struct RollCamApp: App {
    let container: ModelContainer

    @State private var router = Router()
    @State private var settings = AppSettings()
    @State private var hr = HeartRateMonitor()

    init() {
        logger.notice("Launching RollCam")
        // The SwiftData store schema can drift between sideloads as the model
        // evolves. Try the current schema once; if the on-disk store predates
        // it, wipe the store at our known URL and retry; finally fall back to
        // an in-memory store so the app always renders rather than crashing.
        do {
            container = try Self.makeContainer()
        } catch {
            logger.error("ModelContainer init failed: \(error.localizedDescription, privacy: .public). Wiping store and retrying.")
            Self.wipeStoreFiles()
            do {
                container = try Self.makeContainer()
            } catch {
                logger.fault("ModelContainer init failed after wipe. Falling back to in-memory store.")
                do {
                    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: Session.self, configurations: cfg)
                } catch {
                    fatalError("Couldn't create in-memory ModelContainer: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(settings)
                .environment(hr)
                .preferredColorScheme(.dark)
                .tint(RC.hr)
                .onAppear { SampleData.seedIfNeeded(into: container.mainContext) }
        }
        .modelContainer(container)
    }

    // MARK: - Store helpers

    private static let storeURL: URL = {
        let support = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)) ?? URL(filePath: NSTemporaryDirectory())
        return support.appending(path: "RollCam.store")
    }()

    private static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: Session.self, configurations: config)
    }

    private static func wipeStoreFiles() {
        let fm = FileManager.default
        let base = storeURL.path()
        for suffix in ["", "-shm", "-wal", "-journal"] {
            try? fm.removeItem(atPath: base + suffix)
        }
    }
}
