import 'package:ottobit/services/blockly_to_insertcode.dart';

/// Service để quản lý Room ID được chia sẻ giữa các màn hình
class RoomIdService {
  static RoomIdService? _instance;
  String? _roomId;

  // Singleton pattern
  static RoomIdService get instance {
    _instance ??= RoomIdService._internal();
    return _instance!;
  }

  RoomIdService._internal();

  /// Lấy Room ID hiện tại, tạo mới nếu chưa có
  String getRoomId() {
    if (_roomId == null) {
      _roomId = BlocklyToInsertCode.generateRoomId();
    }
    return _roomId!;
  }

  /// Đặt Room ID cụ thể
  void setRoomId(String roomId) {
    _roomId = roomId;
  }

  /// Tạo Room ID mới
  String generateNewRoomId() {
    _roomId = BlocklyToInsertCode.generateRoomId();
    return _roomId!;
  }

  /// Kiểm tra xem có Room ID không
  bool get hasRoomId => _roomId != null;

  /// Reset Room ID
  void reset() {
    _roomId = null;
  }
}
