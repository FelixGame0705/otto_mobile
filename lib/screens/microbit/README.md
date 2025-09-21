# micro:bit BLE Integration

Tính năng này cho phép kết nối và giao tiếp với micro:bit thông qua Bluetooth Low Energy (BLE).

## Cách sử dụng

### 1. Kết nối với micro:bit

1. Mở Blockly Editor
2. Nhấn nút Bluetooth (🔵) trên thanh công cụ
3. Nhấn "Connection Settings" để mở màn hình kết nối
4. Nhấn "Scan" để tìm kiếm thiết bị micro:bit
5. Chọn thiết bị micro:bit từ danh sách và nhấn "Connect"

### 2. Gửi chương trình đến micro:bit

1. Tạo chương trình Blockly
2. Nhấn nút "Send to micro:bit" (🔵) trên thanh công cụ
3. Chương trình sẽ được gửi đến micro:bit qua BLE

### 3. Xem dữ liệu nhận được

1. Mở micro:bit panel bằng nút Bluetooth
2. Dữ liệu từ micro:bit sẽ hiển thị trong phần "Received Data"
3. Sử dụng nút "Clear" để xóa dữ liệu cũ

## Code micro:bit mẫu

Để sử dụng với ứng dụng này, hãy tải code sau lên micro:bit:

```javascript
// 1. Enable Bluetooth and UART service
bluetooth.startUartService()

// 2. Connection indicator
let isConnected = false

// 3. Handle Bluetooth connection
bluetooth.onBluetoothConnected(function () {
    isConnected = true
    basic.showIcon(IconNames.Yes)
    basic.pause(1000)
    basic.clearScreen()

    // Send welcome message
    bluetooth.uartWriteString("Hello from micro:bit!\\n")
})

// 4. Handle Bluetooth disconnection
bluetooth.onBluetoothDisconnected(function () {
    isConnected = false
    basic.showIcon(IconNames.No)
    basic.pause(1000)
    basic.clearScreen()
})

// 5. Handle received data (Echo back)
bluetooth.onUartDataReceived(serial.delimiters(Delimiters.NewLine), function () {
    let received = bluetooth.uartReadUntil(serial.delimiters(Delimiters.NewLine))

    // Echo back the received data
    bluetooth.uartWriteString("Echo: " + received + "\\n")

    // Show received data on LED matrix
    basic.showString(received)
    basic.pause(1000)
    basic.clearScreen()

    // Send confirmation
    bluetooth.uartWriteString("Data received and processed\\n")
})

// 6. Main loop - send periodic status
basic.forever(function () {
    if (isConnected) {
        // Send status every 5 seconds
        bluetooth.uartWriteString("Status: Connected, Time: " + control.millis() + "ms\\n")
        basic.pause(5000)
    } else {
        // Show connection status
        basic.showLeds(`
            . . . . .
            . # . # .
            . . . . .
            # . . . #
            . # # # .
        `)
        basic.pause(1000)
        basic.clearScreen()
        basic.pause(1000)
    }
})

// 7. Button A - Send custom message
input.onButtonPressed(Button.A, function () {
    if (isConnected) {
        bluetooth.uartWriteString("Button A pressed!\\n")
        basic.showIcon(IconNames.Heart)
    }
})

// 8. Button B - Send sensor data
input.onButtonPressed(Button.B, function () {
    if (isConnected) {
        let temp = input.temperature()
        let light = input.lightLevel()
        bluetooth.uartWriteString("Sensors: Temp=" + temp + "°C, Light=" + light + "\\n")
        basic.showIcon(IconNames.Diamond)
    }
})

// 9. Shake gesture - Send accelerometer data
input.onGesture(Gesture.Shake, function () {
    if (isConnected) {
        let x = input.acceleration(Dimension.X)
        let y = input.acceleration(Dimension.Y)
        let z = input.acceleration(Dimension.Z)
        bluetooth.uartWriteString("Shake: X=" + x + ", Y=" + y + ", Z=" + z + "\\n")
        basic.showIcon(IconNames.Square)
    }
})
```

## Tính năng

- **Kết nối BLE**: Tự động quét và kết nối với micro:bit
- **Gửi dữ liệu**: Gửi chương trình Blockly đã biên dịch đến micro:bit
- **Nhận dữ liệu**: Hiển thị dữ liệu từ micro:bit trong thời gian thực
- **Giao diện trực quan**: Hiển thị trạng thái kết nối và dữ liệu nhận được

## Yêu cầu

- Android 6.0+ với hỗ trợ BLE
- micro:bit với firmware hỗ trợ BLE UART
- Quyền truy cập Bluetooth và vị trí

## Xử lý lỗi

- Nếu không thể kết nối, kiểm tra Bluetooth đã bật
- Nếu không tìm thấy thiết bị, đảm bảo micro:bit đang ở chế độ kết nối
- Nếu mất kết nối, thử kết nối lại từ màn hình cài đặt
