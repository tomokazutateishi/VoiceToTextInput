import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("microphoneGain") private var gain: Double = 2.5

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    var body: some View {
        Form {
            Section("マイク感度") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $gain, in: 1...5, step: 0.5)
                    Text("現在: \(String(format: "%.1f", gain))倍（小さい声や遠くの声を拾いやすくします）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            Section("使い方") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• ⌥ Option + Space で録音の開始/停止")
                    Text("• テキスト入力欄にカーソルを置いてから録音してください")
                    Text("• 録音を停止すると、認識したテキストがカーソル位置に入力されます")
                }
                .padding(.vertical, 4)
            }
            Section("必要な権限") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• マイク: 音声入力のため")
                    Text("• 音声認識: テキスト変換のため")
                    Text("• アクセシビリティ: ⌥ Space とテキスト挿入に必須（初回のみ設定）")
                        .fontWeight(.medium)
                    Text("一度設定すれば完了です。ダイアログが毎回出る場合は、一覧から一度削除してから再度追加してください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("アクセシビリティ設定を開く（初回のみ）") { openAccessibilitySettings() }
                        .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 340)
    }
}
