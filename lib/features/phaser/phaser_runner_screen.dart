import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otto_mobile/features/phaser/phaser_bridge.dart';
import '../../widgets/phaser/status_dialog_widget.dart';

class PhaserRunnerScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProgram;
  const PhaserRunnerScreen({super.key, this.initialProgram});

  @override
  State<PhaserRunnerScreen> createState() => _PhaserRunnerScreenState();
}

class _PhaserRunnerScreenState extends State<PhaserRunnerScreen> {
  late final WebViewController _controller;
  late final PhaserBridge _bridge;
  bool _isLoading = true;
  bool _isGameReady = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Khởi tạo bridge trước
    _bridge = PhaserBridge();
    _setupBridgeCallbacks();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterFromPhaser', onMessageReceived: (msg) {
        try {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          _bridge.handlePhaserMessage(data);
        } catch (e) {
          debugPrint('Error parsing Phaser message: $e');
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          debugPrint('Phaser loaded: $url');
          setState(() {
            _isLoading = false;
            _isGameReady = true;
          });
          // Initialize bridge sau khi page load
          _bridge.initialize(_controller);
          
          if (widget.initialProgram != null) {
            _loadMapAndRunProgram();
          }
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('WebView error: ${error.description}');
          setState(() {
            _isLoading = false;
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          debugPrint('Navigation request: ${request.url}');
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse('https://phaser-map-three.vercel.app/'));
  }

  void _setupBridgeCallbacks() {
    _bridge.onReady = (data) {
      debugPrint('🎉 onReady callback called with data: $data');
      if (mounted) {
        setState(() {
          _isGameReady = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStatusDialog('READY', 'Game is ready!', Colors.green, data);
        });
      }
    };

    _bridge.onVictory = (data) {
      debugPrint('🎉 onVictory callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStatusDialog('VICTORY', 'Congratulations! You won!', Colors.green, data);
        });
      }
    };

    _bridge.onDefeat = (data) {
      debugPrint('💀 onDefeat callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStatusDialog('LOSE', 'Game Over!', Colors.red, data);
        });
      }
    };

    _bridge.onProgress = (data) {
      debugPrint('📊 onProgress callback called with data: $data');
      // Không hiển thị popup cho progress
    };

    _bridge.onError = (data) {
      debugPrint('❌ onError callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStatusDialog('ERROR', 'Game Error Occurred', Colors.orange, data);
        });
      }
    };
  }

  void _showStatusDialog(String status, String title, Color color, Map<String, dynamic> data) {
    debugPrint('🎭 Attempting to show dialog: $status - $title');
    
    // Prevent multiple dialogs
    if (_isDialogShowing) {
      debugPrint('⚠️ Dialog already showing, skipping');
      return;
    }
    
    _isDialogShowing = true;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => WillPopScope(
        onWillPop: () async {
          debugPrint('🔙 Dialog dismissed by back button');
          _isDialogShowing = false;
          return true;
        },
        child: StatusDialogWidget(
          status: status,
          title: title,
          color: color,
          data: data,
          onPlayAgain: () {
            debugPrint('🔄 Play Again pressed');
            _isDialogShowing = false;
            Navigator.pop(context);
            _bridge.resetGame();
          },
          onClose: () {
            debugPrint('✅ Close pressed');
            _isDialogShowing = false;
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) {
      debugPrint('🔚 Dialog closed');
      _isDialogShowing = false;
    });
  }

  Future<void> _loadMapAndRunProgram() async {
    if (widget.initialProgram != null) {
      await _bridge.loadMapAndRunProgram('basic1', widget.initialProgram!);
    }
  }

  Future<void> _loadMap(String mapKey) async {
    await _bridge.loadMap(mapKey);
  }

  Future<void> _runProgram() async {
    if (widget.initialProgram != null) {
      await _bridge.runProgram(widget.initialProgram!);
    } else {
      await _bridge.sendTestProgram();
    }
  }

  Future<void> _pauseGame() async {
    await _bridge.pauseGame();
  }

  Future<void> _resumeGame() async {
    await _bridge.resumeGame();
  }

  Future<void> _resetGame() async {
    await _bridge.resetGame();
  }

  Future<void> _getGameStatus() async {
    final status = await _bridge.getGameStatus();
    if (status != null) {
      _showStatusDialog('STATUS', 'Game Status', Colors.blue, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phaser Robot Game'),
        actions: [
          if (_isGameReady) ...[
            IconButton(
              icon: const Icon(Icons.play_circle),
              onPressed: _runProgram,
              tooltip: 'Run Program',
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _resumeGame,
              tooltip: 'Resume',
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _pauseGame,
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetGame,
              tooltip: 'Reset',
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _getGameStatus,
              tooltip: 'Status',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading game...'),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _isGameReady ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _loadMap('basic1'),
            child: const Text('B1'),
            tooltip: 'Load Basic1 Map',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _loadMap('basic2'),
            child: const Text('B2'),
            tooltip: 'Load Basic2 Map',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _runProgram,
            child: const Icon(Icons.play_arrow),
            tooltip: 'Run Program',
          ),
        ],
      ) : null,
    );
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}
