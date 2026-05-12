import Foundation
import AppKit
import Carbon

enum TextInserterError: LocalizedError {
    case failToCopyPaste

    var errorDescription: String? {
        switch self {
        case .failToCopyPaste:
            return "貼り付けのシミュレーションに失敗しました。"
        }
    }
}

final class TextInserterService {
    private init() {}

    /// テキストをカーソル位置に挿入（クリップボード＋Cmd+V。Cursor/VS Code等で確実に動作）
    static func insertText(_ text: String) async throws {
        guard !text.isEmpty else { return }
        try await simulateCopyPaste(text)
    }

    /// クリップボードにコピーして Cmd+V をシミュレート
    static func simulateCopyPaste(_ text: String) async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInserterError.failToCopyPaste
        }
        try await Task.sleep(nanoseconds: 80_000_000)
        await simulateKeyDown(key: CGKeyCode(kVK_ANSI_V), with: .maskCommand)
    }

    private static func simulateKeyDown(key: CGKeyCode, with flags: CGEventFlags) async {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        keyDown?.flags = flags
        if #available(macOS 15.0, *) {
            keyDown?.timestamp = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        }
        keyDown?.post(tap: .cghidEventTap)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyUp?.flags = flags
        if #available(macOS 15.0, *) {
            keyUp?.timestamp = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        }
        keyUp?.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}
