import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Bridge để giao tiếp với Phaser game qua PhaserChannel
class PhaserBridge {
  WebViewController? _controller;
  String? _currentMap;
  Map<String, dynamic>? _currentProgram;
  
  // Callbacks
  Function(Map<String, dynamic>)? onVictory;
  Function(Map<String, dynamic>)? onDefeat;
  Function(Map<String, dynamic>)? onProgress;
  Function(Map<String, dynamic>)? onError;
  Function(Map<String, dynamic>)? onReady;

  // Pending requests for async operations
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  void initialize(WebViewController controller) {
    _controller = controller;
    _setupMessageListener();
  }

  void _setupMessageListener() {
    _controller?.runJavaScript('''
      console.log('🔧 Setting up PhaserChannel listeners...');
      
      // Method 1: Direct postMessage listener (chính)
      window.addEventListener('message', function(event) {
        console.log('📨 Raw message received:', event.data);
        if (event.data && event.data.channel === 'PhaserChannel') {
          console.log('✅ PhaserChannel message received:', event.data);
          if (window.FlutterFromPhaser) {
            window.FlutterFromPhaser.postMessage(JSON.stringify(event.data));
          }
        }
      });
      
      // Method 2: PhaserChannel event listeners (backup)
      function setupPhaserChannelListeners() {
        if (window.PhaserChannel) {
          console.log('✅ PhaserChannel found, setting up listeners...');
          console.log('PhaserChannel methods:', Object.keys(window.PhaserChannel));
          
          // Victory listener
          window.PhaserChannel.on('VICTORY', function(data) {
            console.log('🎉 Victory event received:', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'victory',
                data: data
              }));
            }
          });
          
          // Defeat listener
          window.PhaserChannel.on('LOSE', function(data) {
            console.log('💀 Defeat event received:', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'defeat',
                data: data
              }));
            }
          });
          
          // Progress listener
          window.PhaserChannel.on('progress', function(data) {
            console.log('📊 Progress event received:', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'progress',
                data: data
              }));
            }
          });
          
          // Status Update listener (backup)
          window.PhaserChannel.on('status_update', function(data) {
            console.log('📊 Status Update event received:', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'status_update',
                data: data
              }));
            }
          });

          // Error listener
          window.PhaserChannel.on('error', function(data) {
            console.log('❌ Error event received:', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'error',
                data: data
              }));
            }
          });
          
          // Ready listener
          window.PhaserChannel.on('ready', function(data) {
            console.log('✅ Ready event received (lowercase):', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'ready',
                data: data
              }));
            }
          });
          // READY (uppercase) listener to match WebViewMessenger
          window.PhaserChannel.on('READY', function(data) {
            console.log('✅ READY event received (uppercase):', data);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'ready', // normalize to lowercase for Dart side
                data: data
              }));
            }
          });
          
          // Test victory function
          window.testVictoryEvent = function() {
            console.log(' Testing victory event...');
            window.PhaserChannel.sendVictory({
              test: true,
              score: 1000,
              mapKey: 'basic1',
              collectedBatteries: 5,
              timestamp: Date.now()
            });
          };
          
          console.log('✅ All PhaserChannel listeners setup complete');
        } else {
          console.log('❌ PhaserChannel not found, retrying in 1 second...');
          setTimeout(setupPhaserChannelListeners, 1000);
        }
      }
      
      // Setup listeners
      setupPhaserChannelListeners();
      
      // Poll for PhaserChannel if not ready
      let pollCount = 0;
      const pollInterval = setInterval(function() {
        pollCount++;
        if (window.PhaserChannel) {
          console.log('✅ PhaserChannel found after polling');
          setupPhaserChannelListeners();
          clearInterval(pollInterval);
        } else if (pollCount > 10) {
          console.log('❌ PhaserChannel not found after 10 attempts');
          clearInterval(pollInterval);
        }
      }, 500);
      
      console.log('🔧 PhaserChannel listeners setup complete');
    ''');
  }

  // Gửi sự kiện đến game
  Future<void> loadMap(String mapKey) async {
    if (_controller == null) return;
    
    developer.log('🗺️ Loading map: $mapKey');
    await _controller!.runJavaScript('''
      console.log('️ Sending load_map event...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('LOAD_MAP_AND_CHALLENGE', { mapKey: '$mapKey' });
        console.log('✅ load_map event sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
    _currentMap = mapKey;
  }

  Future<void> runProgram(Map<String, dynamic> program) async {
    if (_controller == null) return;
    
    try {
      developer.log('🏃 Running program: ${program['programName']}');
      String programJson = jsonEncode(program);
      await _controller!.runJavaScript('''
        console.log('🏃 Sending run_program event...');
        if (window.PhaserChannel) {
          window.PhaserChannel.sendEvent('RUN_PROGRAM', { program: $programJson });
          console.log('✅ run_program event sent');
        } else {
          console.log('❌ PhaserChannel not available');
          throw new Error('PhaserChannel not available');
        }
      ''');
      _currentProgram = program;
    } catch (e) {
      developer.log('❌ Error running program: $e');
      onError?.call({'error': e.toString(), 'type': 'run_program_error'});
    }
  }

  // Gửi đồng thời mapJson và challengeJson tới game
  Future<void> loadMapAndChallenge({
    required Map<String, dynamic> mapJson,
    required Map<String, dynamic> challengeJson,
  }) async {
    debugPrint('Sending LOAD_MAP_AND_CHALLENGE to Phaser');
    developer.log('📦 Sending LOAD_MAP_AND_CHALLENGE to Phaser');
    if (_controller == null) return;
    try {
      final mapStr = jsonEncode(mapJson);
      final challengeStr = jsonEncode(challengeJson);
      developer.log('📦 Sending LOAD_MAP_AND_CHALLENGE to Phaser');
      await _controller!.runJavaScript('''
        console.log('️ Sending LOAD_MAP_AND_CHALLENGE with payloads...');
        if (window.PhaserChannel) {
          window.PhaserChannel.sendEvent('LOAD_MAP_AND_CHALLENGE', { 
            mapJson: $mapStr, 
            challengeJson: $challengeStr 
          });
          console.log('Sending LOAD_MAP_AND_CHALLENGE event sent');
        } else {
          console.log('❌ PhaserChannel not available');
          throw new Error('PhaserChannel not available');
        }
      ''');
    } catch (e) {
      developer.log('❌ Error sending LOAD_MAP_AND_CHALLENGE: $e');
      onError?.call({'error': e.toString(), 'type': 'load_map_challenge_error'});
    }
  }

  Future<void> pauseGame() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('⏸️ Sending pause_game event...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('pause_game', {});
        console.log('✅ pause_game event sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  Future<void> resumeGame() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('▶️ Sending resume_game event...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('resume_game', {});
        console.log('✅ resume_game event sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  Future<void> resetGame() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('🔄 Sending reset_game event...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('reset_game', {});
        console.log('✅ reset_game event sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  Future<void> restartScene() async {
    if (_controller == null) return;
    
    try {
      // Get current map and challenge data from the scene
      final result = await _controller!.runJavaScriptReturningResult('''
        const current = game.scene.getScene("Scene");
        if (current && current.mapJson && current.challengeJson) {
          return JSON.stringify({
            mapJson: current.mapJson,
            challengeJson: current.challengeJson
          });
        }
        return null;
      ''');
      
      if (result is String && result != 'null' && result.isNotEmpty) {
        final data = jsonDecode(result) as Map<String, dynamic>;
        final mapStr = jsonEncode(data['mapJson']);
        final challengeStr = jsonEncode(data['challengeJson']);
        
        await _controller!.runJavaScript('''
          console.log('🔄 Sending RESTART_SCENE event...');
          if (window.PhaserChannel) {
            window.PhaserChannel.sendEvent('RESTART_SCENE', { 
                mapJson: $mapStr, 
                challengeJson: $challengeStr 
              });
            console.log('✅ RESTART_SCENE event sent');
          } else {
            console.log('❌ PhaserChannel not available');
          }
        ''');
      } else {
        // Fallback: just send empty event
        await _controller!.runJavaScript('''
          console.log('🔄 Sending RESTART_SCENE event (no data)...');
          if (window.PhaserChannel) {
            window.PhaserChannel.sendEvent('RESTART_SCENE', {});
            console.log('✅ RESTART_SCENE event sent');
          } else {
            console.log('❌ PhaserChannel not available');
          }
        ''');
      }
    } catch (e) {
      developer.log('❌ Error restarting scene: $e');
      onError?.call({'error': e.toString(), 'type': 'restart_scene_error'});
    }
  }

  Future<Map<String, dynamic>?> getGameStatus() async {
    if (_controller == null) return null;
    
    try {
      final result = await _controller!.runJavaScriptReturningResult('''
        if (window.PhaserChannel) {
          return JSON.stringify(window.PhaserChannel.getGameStatus());
        }
        return null;
      ''');
      
      if (result is String && result != 'null' && result.isNotEmpty) {
        return jsonDecode(result);
      }
    } catch (e) {
      developer.log('Error getting game status: $e');
    }
    return null;
  }

  // Test method to trigger victory manually
  Future<void> testVictory() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('🧪 Testing victory...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendVictory({ 
          test: true, 
          score: 1000,
          mapKey: 'basic1',
          collectedBatteries: 5,
          timestamp: Date.now()
        });
        console.log('✅ Victory test sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  // Test victory event từ JavaScript
  Future<void> testVictoryEvent() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log(' Testing victory event...');
      if (typeof window.testVictoryEvent === 'function') {
        window.testVictoryEvent();
      } else {
        console.log('❌ testVictoryEvent function not available');
      }
    ''');
  }

  // Test method to trigger progress manually
  Future<void> testProgress() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('🧪 Testing progress...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('progress', { 
          test: true, 
          collectedBatteries: 3,
          totalBatteries: 8,
          percentage: 37.5,
          currentMap: 'basic1',
          timestamp: Date.now()
        });
        console.log('✅ Progress test sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  // Test method to trigger inprogress manually
  Future<void> testInProgress() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('🧪 Testing inprogress...');
      if (window.PhaserChannel) {
        window.PhaserChannel.sendEvent('inprogress', { 
          test: true, 
          collectedBatteries: 2,
          totalBatteries: 5,
          percentage: 40,
          currentMap: 'basic1',
          timestamp: Date.now()
        });
        console.log('✅ InProgress test sent');
      } else {
        console.log('❌ PhaserChannel not available');
      }
    ''');
  }

  // Test connection method
  Future<void> testConnection() async {
    if (_controller == null) return;
    
    await _controller!.runJavaScript('''
      console.log('🔍 Testing PhaserChannel connection...');
      if (window.PhaserChannel) {
        console.log('✅ PhaserChannel found');
        console.log('Channel name:', window.PhaserChannel.options?.channelName);
        console.log('Debug mode:', window.PhaserChannel.options?.debug);
        console.log('Available methods:', Object.keys(window.PhaserChannel));
        
        // Test ping
        if (typeof window.PhaserChannel.ping === 'function') {
          window.PhaserChannel.ping().then(() => {
            console.log('✅ Ping successful');
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'connection_test',
                data: { success: true, message: 'Connection OK' }
              }));
            }
          }).catch((error) => {
            console.log('❌ Ping failed:', error);
            if (window.FlutterFromPhaser) {
              window.FlutterFromPhaser.postMessage(JSON.stringify({
                channel: 'PhaserChannel',
                type: 'event',
                event: 'connection_test',
                data: { success: false, message: error.toString() }
              }));
            }
          });
        } else {
          console.log('⚠️ Ping method not available');
          if (window.FlutterFromPhaser) {
            window.FlutterFromPhaser.postMessage(JSON.stringify({
              channel: 'PhaserChannel',
              type: 'event',
              event: 'connection_test',
              data: { success: true, message: 'PhaserChannel found but ping not available' }
            }));
          }
        }
      } else {
        console.log('❌ PhaserChannel not found');
        if (window.FlutterFromPhaser) {
          window.FlutterFromPhaser.postMessage(JSON.stringify({
            channel: 'PhaserChannel',
            type: 'event',
            event: 'connection_test',
            data: { success: false, message: 'PhaserChannel not found' }
          }));
        }
      }
    ''');
  }

  // Xử lý message từ game - SỬA LỖI CHÍNH
  void handlePhaserMessage(Map<String, dynamic> message) {
    debugPrint('📨 Raw message received: $message');
    
    // Xử lý message từ PhaserChannel
    if (message['channel'] == 'PhaserChannel') {
      final type = message['type'] as String?;
      
      if (type == 'event') {
        final event = message['event'] as String?;
        final data = message['data'] as Map<String, dynamic>? ?? {};
        
        debugPrint('🎮 Processing event: $event with data: $data');
        
        switch (event) {
          case 'victory':
            debugPrint('🎉 VICTORY received: $data');
            _handleVictoryStatus(data);
            break;
          case 'defeat':
            debugPrint('💀 LOSE received: $data');
            onDefeat?.call(data);
            break;
          case 'progress':
            debugPrint('📊 PROGRESS received: $data');
            onProgress?.call(data);
            break;
          case 'error':
            debugPrint('❌ ERROR received: $data');
            onError?.call(data);
            break;
          case 'ready':
            debugPrint('✅ READY received: $data');
            onReady?.call(data);
            break;
          case 'connection_test':
            debugPrint('🔍 Connection test result: $data');
            break;
          default:
            debugPrint('Unknown event: $event');
        }
      }
    } else {
      // Fallback cho format cũ
      final type = message['type'] as String?;
      final data = message['data'] as Map<String, dynamic>? ?? {};
      
      debugPrint('📨 Fallback message processing: type=$type, data=$data');
      
      switch (type) {
        case 'victory':
          _handleVictoryStatus(data);
          break;
        case 'defeat':
          onDefeat?.call(data);
          break;
        case 'progress':
          onProgress?.call(data);
          break;
        case 'error':
          onError?.call(data);
          break;
        case 'ready':
          onReady?.call(data);
          break;
      }
    }
  }

  // Xử lý Victory Status chi tiết
  void _handleVictoryStatus(Map<String, dynamic> data) {
    debugPrint(' Victory Status received: $data');
    
    final victoryInfo = {
      'isVictory': data['isVictory'] ?? true,
      'mapKey': data['mapKey'] ?? 'unknown',
      'score': data['score'] ?? 0,
      'collectedBatteries': data['collectedBatteries'] ?? 0,
      'collectedBatteryTypes': data['collectedBatteryTypes'] ?? {},
      'requiredBatteries': data['requiredBatteries'] ?? {},
      'details': data['details'] ?? {},
      'robotPosition': data['robotPosition'],
      'timestamp': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      'test': data['test'] ?? false,
    };
    
    debugPrint('🏆 Processed victory info: $victoryInfo');
    
    // Gọi callback
    onVictory?.call(victoryInfo);
  }

  // Convenience methods
  Future<void> sendTestProgram() async {
    final testProgram = {
      "version": "1.0.0",
      "programName": "test_program",
      "actions": [
        {"type": "forward", "count": 3},
        {"type": "turnRight"},
        {"type": "forward", "count": 2}
      ]
    };
    await runProgram(testProgram);
  }

  Future<void> loadMapAndRunProgram(String mapKey, Map<String, dynamic> program) async {
    await loadMap(mapKey);
    // Wait a bit for map to load
    await Future.delayed(const Duration(milliseconds: 1000));
    await runProgram(program);
  }

  // Advanced method calling with async support
  Future<T> callGameMethod<T>(String method, Map<String, dynamic> params) async {
    if (_controller == null) throw Exception('Controller not initialized');
    
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    try {
      await _controller!.runJavaScript('''
        if (window.PhaserChannel) {
          window.PhaserChannel.sendRequest('$method', ${jsonEncode(params)})
            .then(result => {
              if (window.FlutterFromPhaser) {
                window.FlutterFromPhaser.postMessage(JSON.stringify({
                  channel: 'PhaserChannel',
                  type: 'methodResponse',
                  requestId: '$requestId',
                  success: true,
                  data: result
                }));
              }
            })
            .catch(error => {
              if (window.FlutterFromPhaser) {
                window.FlutterFromPhaser.postMessage(JSON.stringify({
                  channel: 'PhaserChannel',
                  type: 'methodResponse',
                  requestId: '$requestId',
                  success: false,
                  error: error.message || error.toString()
                }));
              }
            });
        } else {
          throw new Error('PhaserChannel not available');
        }
      ''');
    } catch (e) {
      completer.completeError(Exception('Failed to call game method: $e'));
    }

    return completer.future;
  }

  // Ví dụ sử dụng
  Future<Map<String, dynamic>> getDetailedGameStatus() async {
    return await callGameMethod<Map<String, dynamic>>('getGameStatus', {});
  }

  Future<bool> loadMapWithValidation(String mapKey) async {
    return await callGameMethod<bool>('loadMap', {'mapKey': mapKey});
  }

  // Cleanup
  void dispose() {
    _pendingRequests.clear();
    
    // Cancel all pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Bridge disposed'));
      }
    }
    
    _controller = null;
    onVictory = null;
    onDefeat = null;
    onProgress = null;
    onError = null;
    onReady = null;
  }
}