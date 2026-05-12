import Foundation
import SwiftUI
import Combine
import AppKit
import UserNotifications

@MainActor
final class MainViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var displayText = ""
    @Published var statusMessage = "⌥ Space で録音開始"
    @Published var errorMessage: String?
    @Published var showError = false

    private let speechService = SpeechRecognitionService()
    private var hasRequestedPermissions = false
    private var cancellables = Set<AnyCancellable>()
    private var targetAppForPaste: NSRunningApplication?

    init() {
        speechService.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        Publishers.CombineLatest(speechService.$transcribedText, speechService.$partialText)
            .map { t, p in
                let pt = p.trimmingCharacters(in: .whitespacesAndNewlines)
                let tt = t.trimmingCharacters(in: .whitespacesAndNewlines)
                return pt.isEmpty ? tt : pt
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.displayText, on: self)
            .store(in: &cancellables)
        speechService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    func toggleRecording() {
        if isRecording {
            stopAndInsert()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let myApp = NSRunningApplication.current
        if let front = NSWorkspace.shared.frontmostApplication, front != myApp {
            targetAppForPaste = front
        } else {
            targetAppForPaste = nil
        }
        Task {
            if !hasRequestedPermissions {
                let ok = await speechService.requestPermissions()
                hasRequestedPermissions = true
                if !ok {
                    statusMessage = "権限を許可してください"
                    showError = true
                    return
                }
            }
            do {
                try await speechService.startRecording()
                statusMessage = "録音中... もう一度 ⌥ Space で停止"
            } catch {
                statusMessage = "録音開始に失敗"
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopAndInsert() {
        let text = speechService.stopRecording()
        statusMessage = "⌥ Space で録音開始"
        // ウィンドウは消さず、認識結果を表示したままにする
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let targetApp = targetAppForPaste
        targetAppForPaste = nil
        let doPaste: () async -> Void = { [weak self] in
            guard let self = self else { return }
            do {
                try await TextInserterService.insertText(text)
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.showPasteNotification(text: text)
            }
        }
        if let app = targetApp, app != NSRunningApplication.current, app != NSWorkspace.shared.frontmostApplication {
            app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                await doPaste()
            }
        } else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                await doPaste()
            }
        }
    }

    private func showPasteNotification(text: String) {
        if !UserDefaults.standard.bool(forKey: "hasRequestedNotificationPermission") {
            UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        let content = UNMutableNotificationContent()
        content.title = "音声入力"
        content.body = "テキストをクリップボードにコピーしました。貼り付けられない場合は ⌘V を押してください。"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
