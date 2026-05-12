#!/bin/bash
# VoiceToTextInput を .app バンドルとしてビルドするスクリプト
# macOS の権限ダイアログ（マイク・音声認識）を正しく表示するために .app 形式が必要

set -e
cd "$(dirname "$0")"

echo "Building VoiceToTextInput..."
swift build -c release

BUILD_DIR=".build/release"
APP_NAME="VoiceToTextInput"
APP_DIR="build/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

rm -rf "build"
mkdir -p "${MACOS}" "${RESOURCES}"

# 実行ファイルをコピー
cp "${BUILD_DIR}/VoiceToTextInput" "${MACOS}/"

# Info.plist
cat > "${CONTENTS}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VoiceToTextInput</string>
    <key>CFBundleIdentifier</key>
    <string>com.voicetotextinput.app</string>
    <key>CFBundleName</key>
    <string>VoiceToTextInput</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>音声をテキストに変換するためにマイクへのアクセスが必要です。カーソル位置に文字を入力します。</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>音声認識により、話した内容をテキストに変換してカーソル位置に入力します。</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# アドホック署名（グローバルショートカットに必要）
codesign -s - --force --deep "${APP_DIR}" 2>/dev/null || true

echo "✅ Built: ${APP_DIR}"
echo ""
echo "起動方法:"
echo "  open build/VoiceToTextInput.app"
echo ""
echo "Applications にコピーして Dock から起動:"
echo "  cp -r ${APP_DIR} /Applications/"
echo ""
echo "初回起動時:"
echo "  1. マイクのアクセス許可を求められます → 許可"
echo "  2. 音声認識の許可を求められます → 許可"
echo "  3. システム設定 > プライバシーとセキュリティ > アクセシビリティ でこのアプリを追加"
echo ""
