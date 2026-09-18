# 🚀 MobileDevBar

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%26%20Intel)-purple?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
</p>

> **MobileDevBar** là ứng dụng Menu Bar native trên macOS được thiết kế đặc biệt cho Mobile Developer (iOS & Android), hợp nhất việc quản lý iOS Simulators, Android AVD, Thiết bị vật lý (USB/Wi-Fi), Chiếu màn hình tốc độ cao (scrcpy) và Tự động dọn dẹp Build Cache hàng chục GB chỉ với 1 cú click chuột.

---

## ✨ Tính Năng Nổi Bật

### 1. 🍎 Quản lý iOS Simulator Nâng Cao
* **Nhận diện chính xác theo thời gian thực:** Hiển thị tức thì trạng thái `Booted` (xanh phát sáng) và `Shutdown` của tất cả simulator iOS trên máy Mac.
* **Tự động gom máy đang chạy lên đầu danh sách:** Máy ảo nào đang chạy sẽ tự động bay lên trên cùng để thao tác nhanh nhất.
* **Thao tác nhanh 1 chạm:**
  * Bật/Tắt Dark Mode hệ thống (`xcrun simctl ui appearance`).
  * Giả lập **FaceID** thành công (Pass) hoặc thất bại (Fail).
  * **Mock GPS:** Đặt vị trí giả lập tức thì (Hà Nội, TP.HCM, Cupertino, Tokyo, Singapore...).
  * **Deep Link Opener:** Bắn URL scheme (`myapp://...`) thẳng vào app đang chạy trên máy ảo.
  * **Chụp màn hình:** Cắt bo góc trong suốt không nền (`.alpha`) hoặc chữ nhật (`.ignored`), tự động sao chép vào Clipboard Mac hoặc lưu Desktop.
  * **Quay video:** Quay video chuẩn `.mp4` 10 giây lưu vào thư mục Desktop.
  * **Media & Clipboard:** Nạp ảnh mẫu vào Photos.app của Simulator, đồng bộ nội dung Clipboard giữa máy Mac và Simulator.
  * **Wipe Data:** Xoá trắng dữ liệu máy ảo chỉ với 1 click.

---

### 2. 🤖 Quản lý Android AVD Chuyên Nghiệp
* **Xác thực AVD thật 100%:** Lấy chính xác tên máy AVD thực tế đang liên kết với cổng `emulator-xxxx`.
* **Khởi động nâng cao:** Hỗ trợ **Cold Boot** (`-no-snapshot-load`) và **Wipe Data** (`-wipe-data`).
* **Android Quick Tweaks:**
  * Bật/Tắt Dark Mode (`cmd uimode night yes/no`).
  * **Show Touches:** Bật/Tắt hiển thị vòng tròn chạm màn hình khi demo hoặc quay video.
  * Mở nhanh màn hình **Developer Settings** của Android.
  * Mock vị trí GPS và bắn Deep Link Android (`am start -a android.intent.action.VIEW`).
  * **Screen Mirroring:** Khởi chạy cửa sổ điều khiển máy ảo qua `scrcpy`.
  * Chụp ảnh màn hình trực tiếp vào Clipboard và quay video AVD.

---

### 3. 📱 Thiết Bị Thật & Chiếu Màn Hình (Physical Devices & Mirroring)
* Tự động quét thiết bị cắm ngoài qua cổng USB hoặc mạng Wi-Fi.
* Nhận diện đúng tên hãng và model phần cứng (Samsung, Xiaomi, Google Pixel, iPhone...).
* **Chiếu màn hình siêu mượt (scrcpy):** Độ trễ cực thấp, hỗ trợ tương tác chuột và phím.
* Chụp ảnh màn hình thiết bị thật vào Clipboard Mac và quay video.
* **Wireless ADB:** Kích hoạt chế độ debug không dây qua Wi-Fi (port 5555) chỉ với 1 click.

---

### 4. 🧹 Smart Developer Storage Cleaner (Giải phóng 100GB Cache)
* **Đo dung lượng theo thời gian thực:**
  * Xcode DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  * Android Gradle Caches (`~/.gradle/caches`)
  * Swift PM & CocoaPods Cache
  * iOS DeviceSupport Symbols cũ (Symbols máy thật)
  * Simulator Logs & Caches
  * Xcode Archives cũ
* **Nhãn an toàn trực quan:**
  * 🟢 **`100% Safe`:** An toàn tuyệt đối, không bao giờ mất code, Xcode/Gradle tự động sinh lại khi build.
  * 🟡 **`Selective`:** Cho phép xem lại các bản build phát hành trong Finder trước khi xoá.
* **Nút "Dọn sạch 1-Click":** Dọn dẹp sạch sẽ toàn bộ 5 danh mục an toàn cùng lúc, giải phóng ngay hàng chục GB ổ cứng.

---

### 5. 🎨 Giao Diện Native macOS Đẳng Cấp
* **App Icon 3D Squircle:** Render sắc nét theo ngôn ngữ thiết kế của macOS Sequoia.
* **Menu Bar Extra thuần túy:** Ẩn hoàn toàn khỏi Dock (`LSUIElement = true`), không làm phiền không gian làm việc.
* **Số lượng máy ảo động:** Hiển thị trực tiếp số lượng máy ảo đang bật ngay trên status bar (ví dụ: icon kèm số `1`).
* **Khởi động cùng máy Mac (Launch at Login):** Tích hợp công tắc bật/tắt trong menu Cài đặt (⚙️).
* **Phím tắt toàn cục cực nhanh:**
  * <kbd>⌘1</kbd>: Tab Simulators & AVD
  * <kbd>⌘2</kbd>: Tab Devices & Mirroring
  * <kbd>⌘3</kbd>: Tab Quick Tools (Dọn Cache & LAN IP)
  * <kbd>⌘F</kbd>: Tìm kiếm nhanh thiết bị
  * <kbd>⌘R</kbd>: Làm mới danh sách thiết bị

---

## 🛠 Hướng Dẫn Cài Đặt & Biên Dịch

### Yêu Cầu Hệ Thống
* macOS 13.0 (Ventura) trở lên.
* Xcode Command Line Tools (`xcode-select --install`).
* *(Tùy chọn cho tính năng chiếu màn hình):* `brew install scrcpy`

### Biên Dịch Từ Mã Nguồn (Build from Source)
```bash
# Clone repository
git clone https://github.com/your-repo/MobileDevBar.git
cd MobileDevBar

# Biên dịch Release và đóng gói thành App Bundle
./build_app.sh

# Cài đặt vào thư mục Ứng Dụng của Mac
cp -R "MobileDevBar.app" /Applications/

# Khởi chạy ứng dụng
open /Applications/MobileDevBar.app
```

---

## 📄 Bản Quyền
Dự án được phát hành theo giấy phép [MIT License](LICENSE).
