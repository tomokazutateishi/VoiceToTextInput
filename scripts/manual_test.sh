#!/bin/bash
# 手動テスト用スクリプト
# 1. ビルド 2. 起動 3. テスト手順を表示

set -e
cd "$(dirname "$0")/.."

echo "=== ビルド ==="
./build_app.sh

echo ""
echo "=== アプリ起動 ==="
open build/VoiceToTextInput.app

echo ""
echo "=== 手動テスト手順 ==="
echo "1. メモ帳やテキストエディタを開き、入力欄にカーソルを置く"
echo "2. ⌥ Option + Space で録音開始（録音ウィンドウが表示される）"
echo "3. 「こんにちは、テストです」と話す"
echo "4. ⌥ Option + Space で録音停止"
echo "5. 認識されたテキストがカーソル位置に入力されることを確認"
echo ""
echo "※ アクセシビリティ権限が必要です（設定 > アクセシビリティ設定を開く）"
