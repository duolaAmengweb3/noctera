import Foundation
import AVFoundation
import Speech

/// On-device voice capture → live transcript. Foreground use; falls back to typing if unavailable.
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
        transcript = ""
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        request = req
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak req] buf, _ in
                req?.append(buf)
            }
            engine.prepare(); try engine.start()
            isRecording = true
            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result { Task { @MainActor in self.transcript = result.bestTranscription.formattedString } }
                if error != nil || (result?.isFinal ?? false) { Task { @MainActor in self.stop() } }
            }
        } catch {
            isRecording = false
        }
    }

    func stop() {
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        request?.endAudio(); task?.cancel()
        request = nil; task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension AVAudioApplication {
    static func requestRecordPermissionAsync() async -> Bool {
        await withCheckedContinuation { c in
            AVAudioApplication.requestRecordPermission { c.resume(returning: $0) }
        }
    }
}
