#!/bin/bash
set -e

APP_NAME="DeviceBar"
VERSION="1.1.0"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
APP_BUNDLE="${APP_NAME}.app"
STAGING_DIR=".dmg_staging"

echo "💿 [1/3] Đang chuẩn bị đóng gói DMG cho ${APP_NAME} v${VERSION}..."

# Kiểm tra file app bundle đã tồn tại chưa
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ Không tìm thấy ${APP_BUNDLE}. Hãy chạy ./build_app.sh trước."
    exit 1
fi

# Dọn dẹp staging cũ và DMG cũ
rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"

# Copy app và tạo symlink Applications
echo "📁 [2/3] Copy ứng dụng và tạo liên kết /Applications..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# Tạo file DMG bằng hdiutil
echo "🚀 [3/3] Đang nén thành file DMG..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

# Dọn dẹp staging
rm -rf "${STAGING_DIR}"

echo "✅ Hoàn tất tạo bộ cài đặt DMG: $(pwd)/${DMG_NAME}"
echo "👉 Kích thước: $(du -sh "${DMG_NAME}" | awk '{print $1}')"
