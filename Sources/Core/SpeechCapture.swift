import Foundation
import AVFoundation
import Speech

/// On-device voice capture → live transcript. Foreground use; falls back to typing if unavailable.
/// Recording ends ONLY on `stop()` — pauses, per-utterance finalization, and interruptions
/// (calls/Siri) never end the session; they roll a fresh recognition segment underneath a
/// continuously-running audio engine and accumulate text into `committed`.
@MainActor
final class SpeechCapture: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var authorized = false
    @Published var available = true

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // --- transcript state (all MainActor-isolated) ---
    private var committed = ""          // text from segments that have finalized on a pause
    private var segmentPartial = ""     // latest partial of the live segment
    private var segmentSeq = 0          // bumps per segment; stale callbacks are dropped
    private var consecutiveErrors = 0   // real errors with no text — guards a wedged recognizer
    private static let maxConsecutiveErrors = 3
    private var interrupted = false
    private var interruptionObserver: NSObjectProtocol?

    func requestAuth() async {
        let speech = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        let mic = await AVAudioApplication.requestRecordPermissionAsync()
        authorized = speech && mic
        available = recognizer?.isAvailable ?? false
    }

    func start() {
        guard authorized, let recognizer, recognizer.isAvailable else { return }
        stop()
        transcript = ""; committed = ""; segmentPartial = ""
        consecutiveErrors = 0; interrupted = false
        do {
            try startEngine()
            isRecording = true
            observeInterruptions()
            beginSegment()
        } catch {
            isRecording = false
        }
    }

    func stop() {
        isRecording = false // set first so in-flight callbacks don't roll a new segment
        removeInterruptionObserver()
        teardownSegment()
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        foldPartial() // keep the last, not-yet-finalized words (e.g. user taps Save mid-sentence)
        if !committed.isEmpty { transcript = committed }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Engine / segments

    private func startEngine() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        // Tap stays installed for the whole session and forwards audio to whatever
        // recognition request is current — segments rotate underneath it.
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buf, _ in
            self?.request?.append(buf)
        }
        engine.prepare()
        try engine.start()
    }

    /// Start one recognition segment. On-device recognition finalizes after each pause (and has
    /// a per-request audio cap); when it does we commit the text and roll a fresh segment, so
    /// recording continues seamlessly across pauses.
    private func beginSegment() {
        guard isRecording, !interrupted, request == nil, let recognizer else { return }
        segmentSeq += 1
        let seq = segmentSeq
        segmentPartial = ""
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        request = req
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            // Snapshot off the background queue; all state is touched only on the MainActor below.
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                guard let self, self.isRecording, seq == self.segmentSeq else { return } // drop stale
                if let text {
                    // Monotonic guard: ignore a shorter (reordered) partial of the same segment.
                    if text.count >= self.segmentPartial.count {
                        self.segmentPartial = text
                        self.refreshTranscript()
                    }
                    if isFinal { self.endSegment(final: true) }
                } else if failed {
                    self.endSegment(final: false)
                }
            }
        }
    }

    /// Fold the finished segment into `committed` and open the next one.
    private func endSegment(final: Bool) {
        guard isRecording, !interrupted else { return }
        let text = segmentPartial
        if !text.isEmpty {
            committed = committed.isEmpty ? text : committed + " " + text
        }
        // Spin guard: only real errors that produced NO text count. A clean final (even on
        // silence) resets the counter, so staying quiet never stops recording.
        if final || !text.isEmpty { consecutiveErrors = 0 }
        else { consecutiveErrors += 1 }
        segmentPartial = ""
        refreshTranscript()
        task = nil; request = nil
        if consecutiveErrors >= Self.maxConsecutiveErrors {
            available = false
            stop()
            return
        }
        beginSegment()
    }

    private func teardownSegment() {
        request?.endAudio(); task?.cancel()
        request = nil; task = nil
        segmentSeq += 1 // invalidate any in-flight callbacks
    }

    private func foldPartial() {
        guard !segmentPartial.isEmpty else { return }
        committed = committed.isEmpty ? segmentPartial : committed + " " + segmentPartial
        segmentPartial = ""
    }

    private func refreshTranscript() {
        if committed.isEmpty { transcript = segmentPartial }
        else if segmentPartial.isEmpty { transcript = committed }
        else { transcript = committed + " " + segmentPartial }
    }

    // MARK: - Interruptions (calls, Siri, alarms) — pause & resume, never lose the session

    private func observeInterruptions() {
        removeInterruptionObserver()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated { self?.handleInterruption(note) }
        }
    }

    private func removeInterruptionObserver() {
        if let o = interruptionObserver { NotificationCenter.default.removeObserver(o) }
        interruptionObserver = nil
    }

    private func handleInterruption(_ note: Notification) {
        guard isRecording,
              let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            interrupted = true
            teardownSegment()
            if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
            foldPartial() // preserve words said right up to the interruption
            refreshTranscript()
        case .ended:
            let opts = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            guard opts.contains(.shouldResume) else { return }
            interrupted = false
            do { try startEngine(); beginSegment() }
            catch { stop() } // can't resume → end cleanly rather than strand a dead orb
        @unknown default:
            break
        }
    }
}

extension AVAudioApplication {
    static func requestRecordPermissionAsync() async -> Bool {
        await withCheckedContinuation { c in
            AVAudioApplication.requestRecordPermission { c.resume(returning: $0) }
        }
    }
}
