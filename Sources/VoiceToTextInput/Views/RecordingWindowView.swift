import SwiftUI
import AppKit

/// NSVisualEffectView を SwiftUI で使うためのラッパー（半透明ブラー）
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct RecordingWindowView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: viewModel.isRecording ? 16 : 0) {
            HStack(spacing: 8) {
                RecordingIndicatorView(isRecording: viewModel.isRecording)
                Text(viewModel.isRecording ? "録音中" : "待機中")
                    .font(.system(size: 15, weight: .semibold))
            }
            if viewModel.isRecording {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.displayText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .id("textEnd")
                    }
                    .frame(maxHeight: 160)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: viewModel.displayText) { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("textEnd", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo("textEnd", anchor: .bottom)
                    }
                }
                Text(viewModel.statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Text(viewModel.statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(viewModel.isRecording ? 16 : 10)
        .frame(
            minWidth: viewModel.isRecording ? 420 : 160,
            minHeight: viewModel.isRecording ? 260 : 28
        )
        .background(Color.clear)
    }
}

/// 録音中はパルスアニメーションするインジケーター
private struct RecordingIndicatorView: View {
    let isRecording: Bool
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(isRecording ? Color.red : Color.blue)
            .frame(width: 14, height: 14)
            .scaleEffect(isRecording ? pulseScale : 1.0)
            .onChange(of: isRecording) { recording in
                if recording {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulseScale = 1.2
                    }
                } else {
                    pulseScale = 1.0
                }
            }
            .onAppear {
                if isRecording {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulseScale = 1.2
                    }
                }
            }
    }
}
