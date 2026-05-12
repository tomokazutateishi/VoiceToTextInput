import Foundation
import Speech
import AVFoundation

/// リアルタイム音声認識サービス（macOS Speech Framework）
@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var partialText = ""
    @Published private(set) var errorMessage: String?
    @Published var isAvailable = false

    /// マイク感度（1.0=標準、2.5=2.5倍、4.0=4倍）
    var microphoneGain: Float {
        get {
            let v = UserDefaults.standard.double(forKey: "microphoneGain")
            if v == 0 { return 2.5 }
            return Float(max(1, min(5, v)))
        }
        set { UserDefaults.standard.set(Double(max(1, min(5, newValue))), forKey: "microphoneGain") }
    }

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private let locale: Locale

    var displayText: String {
        let p = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty { return p }
        return t
    }

    init(locale: Locale = Locale(identifier: "ja-JP")) {
        self.locale = locale
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        isAvailable = speechRecognizer?.isAvailable ?? false
        speechRecognizer?.delegate = self
    }

    func requestPermissions() async -> Bool {
        // マイク権限
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .audio) { cont.resume(returning: $0) }
            }
            if !granted {
                errorMessage = "マイクへのアクセスが許可されていません"
                return false
            }
        case .denied, .restricted:
            errorMessage = "マイクへのアクセスが拒否されています。システム環境設定から許可してください。"
            return false
        @unknown default:
            return false
        }

        // 音声認識権限
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self.isAvailable = self.speechRecognizer?.isAvailable ?? false
                        self.errorMessage = nil
                    case .denied:
                        self.errorMessage = "音声認識が拒否されました"
                        self.isAvailable = false
                    case .restricted:
                        self.errorMessage = "音声認識が制限されています"
                        self.isAvailable = false
                    case .notDetermined:
                        self.errorMessage = "音声認識の許可が未設定です"
                        self.isAvailable = false
                    @unknown default:
                        self.isAvailable = false
                    }
                    cont.resume()
                }
            }
        }
        return isAvailable
    }

    func startRecording() async throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        guard !isRecording else { return }

        transcribedText = ""
        partialText = ""
        errorMessage = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let gain = microphoneGain

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let request = self?.recognitionRequest else { return }
            let boosted = Self.applyGain(gain, to: buffer)
            request.append(boosted)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            // 起動失敗時はtapを取り除いてからエラーを投げる
            inputNode.removeTap(onBus: 0)
            throw error
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.transcribedText = text
                        self.partialText = ""
                    } else {
                        self.partialText = text
                    }
                }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopRecordingInternal()
                }
            }
        }

        isRecording = true
    }

    func stopRecording() -> String {
        stopRecordingInternal()
        return transcribedText.isEmpty ? partialText : transcribedText
    }

    private static func applyGain(_ gain: Float, to buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        guard gain != 1.0 else { return buffer }
        let format = buffer.format
        let frameCount = buffer.frameLength
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return buffer
        }
        outBuffer.frameLength = frameCount
        if let src = buffer.floatChannelData, let dst = outBuffer.floatChannelData {
            let channels = Int(format.channelCount)
            for ch in 0..<channels {
                for i in 0..<Int(frameCount) {
                    let v = src[ch][i] * gain
                    dst[ch][i] = max(-1, min(1, v))
                }
            }
        }
        return outBuffer
    }

    private func stopRecordingInternal() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        if transcribedText.isEmpty && !partialText.isEmpty {
            transcribedText = partialText
        }
    }
}

extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}

enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "音声認識が利用できません。ネットワーク接続を確認してください。"
        case .requestCreationFailed:
            return "音声認識リクエストの作成に失敗しました。"
        }
    }
}
