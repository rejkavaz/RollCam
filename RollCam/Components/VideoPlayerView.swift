import SwiftUI
import AVFoundation
import Observation

// Plays a recorded roll and exposes scrub/seek synced to the HR graph.
// All local — the file is the on-device recording captured by CameraController.
@Observable
final class VideoController {
    @ObservationIgnored let player = AVPlayer()
    private(set) var duration: Double = 0
    private(set) var progress: Double = 0     // 0...1 playback position
    private(set) var hasVideo = false
    var isPlaying = false

    @ObservationIgnored private var url: URL?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    /// Load a recording from its resolved file URL. No-ops if the file is
    /// missing (e.g. Simulator runs, or a temp clip the OS has since purged).
    func load(url newURL: URL?) {
        guard let newURL, FileManager.default.fileExists(atPath: newURL.path) else { return }
        guard newURL != url else { return }
        url = newURL
        hasVideo = true

        // Recording left the shared audio session in record mode; switch it
        // back to playback so the clip's audio is audible.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let item = AVPlayerItem(url: newURL)
        player.replaceCurrentItem(with: item)
        player.isMuted = false

        Task { @MainActor in
            if let d = try? await item.asset.load(.duration) {
                let secs = CMTimeGetSeconds(d)
                if secs.isFinite, secs > 0 { duration = secs }
            }
        }

        addObservers(for: item)
    }

    private func addObservers(for item: AVPlayerItem) {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main
        ) { [weak self] t in
            guard let self, self.duration > 0 else { return }
            self.progress = min(1, max(0, CMTimeGetSeconds(t) / self.duration))
        }

        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = false
            self.player.seek(to: .zero)
            self.progress = 0
        }
    }

    func togglePlay() {
        guard hasVideo else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    /// Seek to a 0...1 fraction of the clip (used by the scrubber).
    func seek(toFraction f: Double) {
        guard duration > 0 else { return }
        let clamped = max(0, min(1, f))
        progress = clamped
        player.seek(to: CMTime(seconds: clamped * duration, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }
}

// Thin AVPlayerLayer host.
struct VideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let v = PlayerUIView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
