# Universal Hex Builder for micro:bit

Hệ thống build Universal Hex và flash qua BLE cho micro:bit V1 & V2 hoàn toàn offline trên Android/Flutter.

## Tính năng chính

- ✅ Build Universal Hex từ Python code sử dụng @microbit/microbit-fs
- ✅ Flash qua BLE sử dụng android-partial-flashing-lib
- ✅ Chạy hoàn toàn offline trên thiết bị Android
- ✅ Hỗ trợ cả micro:bit V1 và V2
- ✅ UI demo với TextField Python và buttons Build/Flash
- ✅ BLE pairing và security

## Kiến trúc

### 1. JavaScript Bundle
- **File**: `assets/js/mbfs.bundle.js`
- **Chức năng**: Bundle @microbit/microbit-fs để build Universal Hex
- **API**: `buildUniversalHex(v1Hex, v2Hex, mainPy)`

### 2. Android Integration
- **Library**: android-partial-flashing-lib
- **Service**: `PartialFlashingService.kt`
- **Method Channel**: `universal_hex_service`

### 3. Flutter Services
- **UniversalHexService**: Quản lý build Universal Hex
- **BleService**: Quản lý BLE connection và pairing
- **UI**: Universal Hex Builder screen

## Cài đặt

### 1. Dependencies
```yaml
dependencies:
  flutter_qjs: ^0.3.15
  path_provider: ^2.1.1
  flutter_blue_plus: ^1.32.10
  permission_handler: ^11.3.1
```

### 2. Assets
```
assets/
├── firmware/
│   ├── micropython-microbit-v1.hex
│   └── micropython-microbit-v2.hex
└── js/
    └── mbfs.bundle.js
```

### 3. Android Configuration
- Thêm android-partial-flashing-lib vào `settings.gradle.kts`
- Đăng ký `PartialFlashingService` trong `AndroidManifest.xml`
- Cấu hình permissions cho BLE

## Sử dụng

### 1. Build Universal Hex
```dart
final universalHex = await UniversalHexService.buildUniversalHex(
  v1Hex: v1Firmware,
  v2Hex: v2Firmware,
  mainPy: pythonCode,
);
```

### 2. Flash qua BLE
```dart
await UniversalHexService.flashHex(
  deviceAddress: deviceAddress,
  hexContent: universalHex,
);
```

### 3. BLE Pairing
```dart
await _bleService.startScan();
// Chọn device từ danh sách
await _bleService.connectToDevice(selectedDevice);
```

## API Reference

### UniversalHexService
- `initialize()`: Khởi tạo QuickJS runtime
- `buildUniversalHex(v1Hex, v2Hex, mainPy)`: Build Universal Hex
- `validateHex(hex)`: Validate hex format
- `getEstimatedSize(v1Hex, v2Hex, mainPy)`: Ước tính kích thước
- `flashHex(deviceAddress, hexContent)`: Flash qua BLE
- `loadFirmwareHex(version)`: Load firmware từ assets

### BleService
- `initialize()`: Khởi tạo BLE service
- `startScan()`: Bắt đầu scan devices
- `stopScan()`: Dừng scan
- `connectToDevice(device)`: Kết nối device
- `disconnect()`: Ngắt kết nối

## Cấu trúc Files

```
lib/
├── services/
│   ├── universal_hex_service.dart
│   └── ble_service.dart
├── screens/
│   └── universal_hex/
│       └── universal_hex_screen.dart
└── routes/
    └── app_routes.dart

android/
├── app/src/main/java/com/otto/ottobit/
│   ├── MainActivity.kt
│   ├── PartialFlashingService.kt
│   └── MethodChannelHandler.kt
└── android-partial-flashing-lib/

assets/
├── firmware/
│   ├── micropython-microbit-v1.hex
│   └── micropython-microbit-v2.hex
└── js/
    └── mbfs.bundle.js
```

## Lưu ý

1. **Firmware**: Cần thay thế firmware mẫu bằng firmware thực tế từ GitHub releases
2. **QuickJS**: Hiện tại sử dụng mock implementation, cần tích hợp flutter_qjs thực tế
3. **BLE Security**: Cần implement MITM/Passkey pairing
4. **Permissions**: Cần cấu hình đầy đủ BLE permissions

## Troubleshooting

### Lỗi thường gặp
1. **Permission denied**: Kiểm tra BLE permissions
2. **Device not found**: Đảm bảo micro:bit đang ở chế độ pairing
3. **Flash failed**: Kiểm tra kết nối BLE và Universal Hex format

### Debug
- Kiểm tra logs trong Android Studio
- Sử dụng BLE scanner để debug kết nối
- Verify Universal Hex format với hex editor

## Tham khảo

- [@microbit/microbit-fs](https://microbit-foundation.github.io/microbit-fs/)
- [Universal Hex Spec](https://tech.microbit.org/software/hex-format/)
- [android-partial-flashing-lib](https://github.com/microbit-foundation/android-partial-flashing-lib)
- [flutter_qjs](https://pub.dev/packages/flutter_qjs)
