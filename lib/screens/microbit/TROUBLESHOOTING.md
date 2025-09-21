# micro:bit BLE Troubleshooting Guide

## Vấn đề: Không thể kết nối với micro:bit đã paired

### Nguyên nhân có thể:

1. **micro:bit đang kết nối với app khác**
   - micro:bit chỉ có thể kết nối với một thiết bị tại một thời điểm
   - Giải pháp: Đóng tất cả app khác đang kết nối với micro:bit

2. **micro:bit chưa được reset**
   - Sau khi kết nối với app khác, micro:bit có thể cần reset
   - Giải pháp: Nhấn nút reset trên micro:bit hoặc tháo pin và lắp lại

3. **Quyền Bluetooth chưa được cấp**
   - Android cần quyền để quét và kết nối BLE
   - Giải pháp: Kiểm tra Settings > Apps > Otto Mobile > Permissions

4. **micro:bit không ở chế độ BLE**
   - micro:bit cần có code BLE được tải lên
   - Giải pháp: Tải code BLE mẫu lên micro:bit

### Các bước khắc phục:

#### Bước 1: Đặt micro:bit vào pairing mode
1. Giữ nút A và B cùng lúc
2. Nhấn và giữ nút reset (nút nhỏ bên cạnh USB)
3. Nếu dùng USB: thả nút reset nhưng vẫn giữ A và B
4. Nếu dùng pin: thả tất cả nút
5. micro:bit sẽ hiển thị "PAIRING MODE" và mã 5 ký tự

#### Bước 2: Pairing với điện thoại
1. Mở Settings > Bluetooth trên điện thoại
2. Tìm micro:bit trong danh sách thiết bị
3. Nhấn vào micro:bit để bắt đầu pairing
4. Nhấn nút A trên micro:bit khi được yêu cầu
5. Nhập mã 6 số hiển thị trên micro:bit (nếu có)
6. micro:bit sẽ hiển thị dấu tick khi thành công

#### Bước 3: Đóng app khác
1. Kiểm tra tất cả app đang chạy trên điện thoại
2. Đóng bất kỳ app nào đang kết nối với micro:bit
3. Có thể cần restart điện thoại

#### Bước 4: Kiểm tra quyền
1. Mở Settings > Apps > Otto Mobile
2. Vào Permissions
3. Đảm bảo các quyền sau được bật:
   - Location (Fine & Coarse)
   - Bluetooth
   - Nearby devices

#### Bước 5: Quét lại
1. Mở app Otto Mobile
2. Vào Blockly Editor
3. Nhấn nút Bluetooth
4. Nhấn "Connection Settings"
5. Nhấn "Refresh" để kiểm tra thiết bị đã paired
6. Nếu không có, nhấn "Scan" để quét lại

#### Bước 6: Kiểm tra code micro:bit
Đảm bảo micro:bit có code BLE đúng:

```javascript
// Code cơ bản cho micro:bit BLE
bluetooth.startUartService()

bluetooth.onBluetoothConnected(function () {
    basic.showIcon(IconNames.Yes)
    bluetooth.uartWriteString("Connected!\\n")
})

bluetooth.onBluetoothDisconnected(function () {
    basic.showIcon(IconNames.No)
})

bluetooth.onUartDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    let received = bluetooth.uartReadUntil(serial.delimiters(Delimiters.NewLine))
    bluetooth.uartWriteString("Echo: " + received + "\\n")
    basic.showString(received)
})
```

### Nếu vẫn không được:

1. **Thử với micro:bit khác** - để xác định vấn đề là ở micro:bit hay app
2. **Kiểm tra Android version** - cần Android 6.0+ với BLE support
3. **Restart điện thoại** - để reset Bluetooth stack
4. **Unpair và pair lại** - trong Bluetooth settings của điện thoại

### Lỗi thường gặp:

- **"Bluetooth is not enabled"** → Bật Bluetooth
- **"micro:bit UART service not found"** → micro:bit chưa có code BLE
- **"Failed to connect"** → micro:bit đang kết nối với app khác
- **"No devices found"** → Kiểm tra quyền Location và Bluetooth
- **"Encrypted connection required"** → Cần pairing với micro:bit trước
- **"TX characteristic not found"** → micro:bit không hỗ trợ UART service
- **"RX characteristic not found"** → micro:bit không hỗ trợ UART service

### Liên hệ hỗ trợ:
Nếu vẫn gặp vấn đề, vui lòng cung cấp:
- Model điện thoại và Android version
- Model micro:bit
- Mô tả chi tiết lỗi
- Screenshot màn hình lỗi
