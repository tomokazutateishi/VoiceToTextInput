#!/bin/bash
# VoiceToTextInput をビルドして起動するスクリプト
# .app バンドルとして起動しないと、マイク・音声認識の権限ダイアログが表示されずクラッシュします

set -e
cd "$(dirname "$0")"

./build_app.sh
open build/VoiceToTextInput.app
