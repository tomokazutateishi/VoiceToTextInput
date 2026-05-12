import XCTest
@testable import VoiceToTextInput

@MainActor
final class SpeechRecognitionTests: XCTestCase {
    func testMicrophoneGainDefault() {
        UserDefaults.standard.removeObject(forKey: "microphoneGain")
        let service = SpeechRecognitionService()
        XCTAssertEqual(service.microphoneGain, 2.5)
    }

    func testMicrophoneGainClamped() {
        UserDefaults.standard.set(10.0, forKey: "microphoneGain")
        let service = SpeechRecognitionService()
        XCTAssertEqual(service.microphoneGain, 5.0)
        UserDefaults.standard.set(0.5, forKey: "microphoneGain")
        let service2 = SpeechRecognitionService()
        XCTAssertEqual(service2.microphoneGain, 1.0)
        UserDefaults.standard.removeObject(forKey: "microphoneGain")
    }
}
