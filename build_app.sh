#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 [1/3] Đang biên dịch MobileDevBar (Release)..."
swift build -c release

BIN_PATH="$DIR/.build/release/MobileDevBar"
APP_DIR="$DIR/MobileDevBar.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "📦 [2/3] Đang đóng gói macOS App Bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/MobileDevBar"
cp "$DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

chmod +x "$MACOS_DIR/MobileDevBar"

echo "✅ [3/3] Hoàn tất đóng gói ứng dụng: $APP_DIR"
echo ""
echo "👉 Để khởi chạy ngay, gõ: open \"$APP_DIR\""
echo "👉 Để cài vào thư mục ứng dụng Mac: cp -R \"$APP_DIR\" /Applications/"
