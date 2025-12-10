import 'package:flutter_test/flutter_test.dart';
import 'package:ottobit/services/room_id_service.dart';

void main() {
  group('RoomIdService Tests', () {
    late RoomIdService roomIdService;

    setUp(() {
      roomIdService = RoomIdService.instance;
      roomIdService.reset(); // Reset để test clean
    });

    test('should generate room ID when first accessed', () {
      final roomId = roomIdService.getRoomId();
      
      expect(roomId, isNotNull);
      expect(roomId, startsWith('room-'));
      expect(roomId, matches(RegExp(r'room-\d{4}\d{1,3}')));
    });

    test('should return same room ID on multiple calls', () {
      final roomId1 = roomIdService.getRoomId();
      final roomId2 = roomIdService.getRoomId();
      
      expect(roomId1, equals(roomId2));
    });

    test('should generate new room ID when requested', () {
      final roomId1 = roomIdService.getRoomId();
      final roomId2 = roomIdService.generateNewRoomId();
      
      expect(roomId1, isNot(equals(roomId2)));
      expect(roomId2, startsWith('room-'));
    });

    test('should set specific room ID', () {
      const testRoomId = 'room-1234567';
      roomIdService.setRoomId(testRoomId);
      
      expect(roomIdService.getRoomId(), equals(testRoomId));
    });

    test('should reset room ID', () {
      roomIdService.getRoomId(); // Generate initial ID
      roomIdService.reset();
      
      expect(roomIdService.hasRoomId, isFalse);
      
      final newRoomId = roomIdService.getRoomId();
      expect(newRoomId, isNotNull);
      expect(newRoomId, startsWith('room-'));
    });

    test('should check if room ID exists', () {
      expect(roomIdService.hasRoomId, isFalse);
      
      roomIdService.getRoomId();
      expect(roomIdService.hasRoomId, isTrue);
    });
  });
}
