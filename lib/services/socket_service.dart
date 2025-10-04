import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  String? _currentRoomId;
  bool _isConnected = false;
  Function(dynamic)? _onActionsReceived;
  
  // Auto-reconnection properties
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  
  // Network monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkAvailable = true;

  // Singleton pattern
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal() {
    _startNetworkMonitoring();
  }

  /// Bắt đầu monitoring network connectivity
  void _startNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = results.any((result) => 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet
        );
        
        if (isConnected != _isNetworkAvailable) {
          _isNetworkAvailable = isConnected;
          debugPrint('🌐 Network status changed: ${_isNetworkAvailable ? "Available" : "Unavailable"}');
          
          if (_isNetworkAvailable && !_isConnected) {
            // Network restored, attempt reconnection
            _attemptReconnection();
          } else if (!_isNetworkAvailable) {
            // Network lost, stop reconnection attempts
            _stopReconnection();
          }
        }
      },
    );
  }

  /// Kết nối tới Socket.IO server
  Future<bool> connect() async {
    try {
      if (_socket != null && _socket!.connected) {
        debugPrint('Socket already connected');
        return true;
      }

      _socket = IO.io(
        'http://163.227.230.168:3000/',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      // Lắng nghe sự kiện kết nối
      _socket!.onConnect((_) {
        debugPrint('✅ Socket connected successfully to http://163.227.230.168:3000/');
        _isConnected = true;
      });

      // Lắng nghe sự kiện ngắt kết nối
      _socket!.onDisconnect((_) {
        debugPrint('🔌 Socket disconnected');
        _isConnected = false;
        _stopHeartbeat();
        _attemptReconnection();
      });

      // Lắng nghe sự kiện lỗi
      _socket!.onConnectError((error) {
        debugPrint('❌ Socket connection error: $error');
        _isConnected = false;
        _stopHeartbeat();
        _attemptReconnection();
      });

      // Lắng nghe sự kiện reconnect
      _socket!.onReconnect((_) {
        debugPrint('🔄 Socket reconnected');
        _isConnected = true;
        _reconnectAttempts = 0;
        _startHeartbeat();
        _rejoinRoomIfNeeded();
      });

      // Lắng nghe sự kiện reconnect error
      _socket!.onReconnectError((error) {
        debugPrint('❌ Socket reconnection error: $error');
        _attemptReconnection();
      });

      // Lắng nghe event actions
      _socket!.on('actions', (data) {
        debugPrint('🤖 Received actions event: ${jsonEncode(data)}');
        if (_onActionsReceived != null) {
          _onActionsReceived!(data);
          debugPrint('✅ Actions callback executed');
        } else {
          debugPrint('⚠️ No actions callback set');
        }
      });

      // Chờ kết nối thành công
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_isConnected) {
        _reconnectAttempts = 0;
        _startHeartbeat();
      }
      
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Error connecting to socket: $e');
      _attemptReconnection();
      return false;
    }
  }

  /// Join room với ID được tạo
  Future<bool> joinRoom(String roomId) async {
    try {
      if (_socket == null || !_socket!.connected) {
        debugPrint('Socket not connected, attempting to connect...');
        final connected = await connect();
        if (!connected) {
          debugPrint('Failed to connect to socket');
          return false;
        }
      }

      _currentRoomId = roomId;
      _socket!.emit('join', {'id': roomId});
      debugPrint('🚪 Emitted join event for room: $roomId');
      return true;
    } catch (e) {
      debugPrint('Error joining room: $e');
      return false;
    }
  }

  /// Tạo room ID ngẫu nhiên
  String generateRoomId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999);
    return 'room-$timestamp-$randomNum';
  }

  /// Lấy room ID hiện tại
  String? get currentRoomId => _currentRoomId;

  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _isConnected && _socket?.connected == true;

  /// Ngắt kết nối
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentRoomId = null;
      debugPrint('Socket disconnected and disposed');
    }
  }

  /// Gửi message tới server
  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
      debugPrint('Emitted $event: ${jsonEncode(data)}');
    } else {
      debugPrint('Cannot emit: Socket not connected');
    }
  }

  /// Lắng nghe event từ server
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }


  /// Hủy lắng nghe event
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  /// Set callback cho event actions
  void setOnActionsReceived(Function(dynamic) callback) {
    _onActionsReceived = callback;
  }

  /// Disconnect Socket.IO (chỉ gọi khi app đóng)
  void forceDisconnect() {
    _stopReconnection();
    _stopHeartbeat();
    _connectivitySubscription?.cancel();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentRoomId = null;
      _onActionsReceived = null;
      debugPrint('🔌 Socket.IO force disconnected');
    }
  }

  /// Thử kết nối lại với exponential backoff
  void _attemptReconnection() {
    if (!_isNetworkAvailable || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('🛑 Stopping reconnection attempts: network=${_isNetworkAvailable}, attempts=$_reconnectAttempts');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds: _baseReconnectDelay.inMilliseconds * pow(2, _reconnectAttempts - 1).toInt(),
    );

    debugPrint('🔄 Attempting reconnection $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!_isConnected && _isNetworkAvailable) {
        await connect();
        if (_currentRoomId != null) {
          await joinRoom(_currentRoomId!);
        }
      }
    });
  }

  /// Dừng thử kết nối lại
  void _stopReconnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  /// Bắt đầu heartbeat để kiểm tra kết nối
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        debugPrint('💓 Heartbeat sent');
      } else {
        debugPrint('💔 Heartbeat failed - connection lost');
        _isConnected = false;
        _stopHeartbeat();
        _attemptReconnection();
      }
    });
  }

  /// Dừng heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Rejoin room nếu cần thiết
  void _rejoinRoomIfNeeded() {
    if (_currentRoomId != null) {
      joinRoom(_currentRoomId!);
    }
  }

  /// Reset reconnection attempts (gọi khi kết nối thành công)
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
  }
}
