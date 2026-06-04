import AVFoundation

// Quiet voice countdown / zone alerts. Routed through the normal audio
// session so it plays in an earpiece (AirPods) without dominating; it does
// not touch the video mic capture.
final class SpeechAnnouncer {
    private let synth = AVSpeechSynthesizer()
    var enabled = true

    func say(_ text: String) {
        guard enabled else { return }
        let u = AVSpeechUtterance(string: text)
        u.rate = AVSpeechUtteranceDefaultSpeechRate
        u.volume = 0.9
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
