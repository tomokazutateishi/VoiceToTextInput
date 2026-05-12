# VoiceToTextInput

Notta・SuperWhisper のような、**バイブコーディング（音声→テキスト入力）** 用の macOS アプリです。  
カーソルがある位置に、話した内容をそのまま入力します。

## 対応環境

- **macOS 13.0 (Ventura) 以上**
- Apple Silicon (M1/M2/M3/M4) および Intel Mac
- 動作確認: macOS Sequoia 15.6, MacBook Pro 14インチ (M4, 16GB)

## 使い方

1. **⌥ Option + Space** で録音を開始
2. テキストを話す
3. もう一度 **⌥ Option + Space** で録音を停止
4. 認識したテキストが、フォーカス中のテキスト欄のカーソル位置に入力される

## ビルド・起動

**重要:** マイク・音声認識の権限のため、`.app` バンドルとして起動する必要があります。`swift run` ではクラッシュします。

```bash
./build_app.sh
open build/VoiceToTextInput.app
```

または一括でビルド＋起動:

```bash
./build_app.sh && open build/VoiceToTextInput.app
```

### 初回起動時の設定

1. **マイク**：ダイアログで「許可」を選択
2. **音声認識**：ダイアログで「許可」を選択
3. **アクセシビリティ**：  
   システム設定 > プライバシーとセキュリティ > アクセシビリティ で  
   `VoiceToTextInput` を追加して許可

## 技術仕様

- **音声認識**: macOS Speech Framework（`SFSpeechRecognizer`）
- **テキスト挿入**: Accessibility API + クリップボードフォールバック（⌘V シミュレート）
- **言語**: 日本語（デフォルト）、`ja-JP` ロケール

## ショートカット

| 操作 | ショートカット |
|------|----------------|
| 録音 開始/停止 | ⌥ Option + Space |

## 注意事項

- 音声認識はインターネット接続が必要な場合があります
- 一部アプリ（Cursor、VS Code、Slack、Gmail など）では、クリップボード経由の貼り付けが使われます
- アクセシビリティ権限がないと、アプリへのテキスト挿入ができません

## 貼り付けがうまくいかない場合

認識されたテキストは常にクリップボードにコピーされます。自動貼り付けが失敗した場合は、**⌘ Command + V** で手動貼り付けしてください。

## ライセンス

MIT
