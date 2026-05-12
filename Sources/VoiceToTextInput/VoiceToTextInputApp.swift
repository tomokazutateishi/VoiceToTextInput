import SwiftUI
import AppKit
import Combine

@main
struct VoiceToTextInputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var recordingWindow: NSWindow?
    private var viewModel: MainViewModel?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let viewModel = MainViewModel()
        self.viewModel = viewModel

        setupRecordingWindow(viewModel: viewModel)
        resizeWindow(forRecording: false)
        showRecordingWindow()
        viewModel.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                if isRecording {
                    self?.showRecordingWindow()
                }
                self?.resizeWindow(forRecording: isRecording)
            }
            .store(in: &cancellables)

        setupGlobalHotkey()
    }

    @objc private func toggleRecording() {
        Task { @MainActor in
            viewModel?.toggleRecording()
        }
    }

    private func setupGlobalHotkey() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            DispatchQueue.main.async {
                self?.viewModel?.toggleRecording()
            }
        }
        func isHotkey(_ event: NSEvent) -> Bool {
            guard event.keyCode == 49 else { return false }
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return mods.contains(.option) && !mods.contains(.command)
        }
        _ = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if isHotkey(event) { handler(event) }
        }
        _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isHotkey(event) {
                handler(event)
                return nil
            }
            return event
        }
    }

    private func setupRecordingWindow(viewModel: MainViewModel) {
        let contentView = RecordingWindowView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false

        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        effectView.addSubview(hostingView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.standbySize.width, height: Self.standbySize.height),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = effectView
        panel.title = "VoiceToTextInput - 音声入力"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.center()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        recordingWindow = panel

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
        ])
    }

    private func showRecordingWindow() {
        guard let window = recordingWindow else { return }
        window.orderFrontRegardless()
    }

    private static let standbySize = NSSize(width: 200, height: 48)
    private static let recordingSize = NSSize(width: 460, height: 320)

    private func resizeWindow(forRecording isRecording: Bool) {
        guard let window = recordingWindow else { return }
        let newSize = isRecording ? Self.recordingSize : Self.standbySize
        let frame = window.frame
        let newOrigin = NSPoint(
            x: frame.minX,
            y: frame.maxY - newSize.height
        )
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        recordingWindow?.orderFrontRegardless()
        return true
    }
}
