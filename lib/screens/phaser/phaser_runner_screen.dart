import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/services/program_storage_service.dart';
import 'package:ottobit/features/phaser/phaser_bridge.dart';
import 'package:ottobit/widgets/phaser/status_dialog_widget.dart';

class PhaserRunnerScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProgram;
  final Map<String, dynamic>? initialMapJson;
  final Map<String, dynamic>? initialChallengeJson;
  final bool embedded;
  final ValueChanged<PhaserBridge>? onBridgeReady;
  final Map<String, dynamic>? Function()? getActionsProgram;
  const PhaserRunnerScreen({
    super.key,
    this.initialProgram,
    this.initialMapJson,
    this.initialChallengeJson,
    this.embedded = false,
    this.onBridgeReady,
    this.getActionsProgram,
  });

  @override
  State<PhaserRunnerScreen> createState() => _PhaserRunnerScreenState();
}

class _PhaserRunnerScreenState extends State<PhaserRunnerScreen> {
  late final WebViewController _controller;
  late final PhaserBridge _bridge;
  bool _isLoading = true;
  bool _isGameReady = false;
  bool _isDialogShowing = false;
  bool _sentInitialLoad = false;
  String _cachedCodeJson = '{}';
  double _webViewZoom = 0.8; // Giảm zoom mặc định từ 1.0 xuống 0.8 (80%)
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.1;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _bridge = PhaserBridge();
    _setupBridgeCallbacks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onBridgeReady?.call(_bridge);
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..addJavaScriptChannel(
        'FlutterFromPhaser',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            _bridge.handlePhaserMessage(data);
          } catch (e) {
            debugPrint('Error parsing Phaser message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Phaser loaded: $url');
            setState(() {
              _isLoading = false;
              _isGameReady = true;
            });
            _bridge.initialize(_controller);
            // Apply initial zoom after page loads
            _applyWebViewZoom(_webViewZoom);
            debugPrint(
              '⏳ Waiting for READY from Phaser before sending payload',
            );
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
        ),
      )
      ..loadRequest(Uri.parse('https://phaser-map-three.vercel.app/'));
  }

  void _setupBridgeCallbacks() {
    _bridge.onReady = (data) {
      debugPrint('🎉 onReady callback called with data: $data');
      if (mounted) {
        setState(() {
          _isGameReady = true;
        });
        _refreshCachedCodeJson();
        _sendInitialPayloadIfAny();
      }
    };

    _bridge.onVictory = (data) {
      debugPrint('🎉 onVictory callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final message = data['message'] as String? ?? 'phaser.victoryDefault'.tr();
          _showStatusDialog(
            'VICTORY',
            message,
            Colors.green,
            data,
          );
        });
      }
    };

    _bridge.onDefeat = (data) {
      debugPrint('💀 onDefeat callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final message = data['message'] as String? ?? 'phaser.defeatDefault'.tr();
          _showStatusDialog('LOSE', message, Colors.red, data);
        });
      }
    };

    _bridge.onProgress = (data) {
      debugPrint('📊 onProgress callback called with data: $data');
    };

    _bridge.onError = (data) {
      debugPrint('❌ onError callback called with data: $data');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStatusDialog(
            'ERROR',
            'phaser.errorDefault'.tr(),
            Colors.orange,
            data,
          );
        });
      }
    };

    _bridge.onProgramCompiled = (data) {
      debugPrint('🤖 onProgramCompiled callback called with data: $data');
    };
  }

  void _showStatusDialog(
    String status,
    String title,
    Color color,
    Map<String, dynamic> data,
  ) {
    debugPrint('🎭 Attempting to show dialog: $status - $title');

    if (_isDialogShowing) {
      debugPrint('⚠️ Dialog already showing, skipping');
      return;
    }

    _isDialogShowing = true;
    final String codeJsonString = _getCodeJsonStringSync();
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
          bridge: _bridge,
          challengeId: () {
            final challengeId =
                widget.initialChallengeJson?['id'] ??
                widget.initialChallengeJson?['challengeId'];
            debugPrint('🔍 Challenge ID for submission: $challengeId');
            debugPrint(
              '🔍 Full challenge data: ${widget.initialChallengeJson}',
            );
            return challengeId;
          }(),
          codeJson: codeJsonString.isNotEmpty
              ? codeJsonString
              : (widget.initialProgram != null
                    ? jsonEncode(widget.initialProgram!)
                    : '{}'),
          onPlayAgain: () {
            debugPrint('🔄 Play Again pressed');
            _isDialogShowing = false;
            Navigator.pop(context);
            if (widget.initialMapJson != null &&
                widget.initialChallengeJson != null) {
              _bridge.restartScene(
                mapJson: widget.initialMapJson!,
                challengeJson: widget.initialChallengeJson!,
              );
            } else {
              debugPrint('❌ Cannot restart: missing mapJson or challengeJson');
            }
          },
          onClose: () {
            debugPrint('✅ Close pressed');
            _bridge.restartScene(
              mapJson: widget.initialMapJson!,
              challengeJson: widget.initialChallengeJson!,
            );
            _isDialogShowing = false;
            Navigator.pop(context);
          },
          onSimulation: widget.getActionsProgram != null
              ? () async {
                  try {
                    final program = widget.getActionsProgram!.call();
                    if (program != null) {
                      debugPrint('▶️ Running simulation from socket actions program');
                      if (widget.initialMapJson != null && widget.initialChallengeJson != null) {
                        await _bridge.loadMapAndChallenge(
                          mapJson: widget.initialMapJson!,
                          challengeJson: widget.initialChallengeJson!,
                        );
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _bridge.runProgram(program);
                      } else {
                        debugPrint('❌ Cannot run simulation: missing mapJson or challengeJson');
                      }
                    } else {
                      debugPrint('ℹ️ No actions program available for simulation');
                    }
                  } catch (e) {
                    debugPrint('❌ Error running simulation: $e');
                  }
                }
              : null,
        ),
      ),
    ).then((_) {
      debugPrint('🔚 Dialog closed');
      _isDialogShowing = false;
    });
  }

  void _refreshCachedCodeJson() async {
    try {
      if (widget.initialProgram != null && widget.initialProgram!.isNotEmpty) {
        _cachedCodeJson = jsonEncode(widget.initialProgram!);
        return;
      }
      final storage = ProgramStorageService();
      final latest = await storage.loadFromPrefs();
      if (latest != null && latest.isNotEmpty) {
        final storedText = latest['codeJson'];
        _cachedCodeJson = storedText is String && storedText.isNotEmpty
            ? storedText
            : jsonEncode(latest);
      }
    } catch (_) {}
  }

  String _getCodeJsonStringSync() {
    if (widget.initialProgram != null && widget.initialProgram!.isNotEmpty) {
      return jsonEncode(widget.initialProgram!);
    }
    if (_cachedCodeJson.isNotEmpty && _cachedCodeJson != '{}') {
      return _cachedCodeJson;
    }
    return '{}';
  }

  Future<void> _loadMapAndRunProgram() async {
    if (widget.initialProgram != null) {
      await _bridge.loadMapAndRunProgram('basic1', widget.initialProgram!);
    }
  }

  void _sendInitialPayloadIfAny() {
    debugPrint('🔍 Sending initial payload if any');
    if (_sentInitialLoad) return;
    if (!_isGameReady) return;
    if (widget.initialMapJson != null && widget.initialChallengeJson != null) {
      _sentInitialLoad = true;
      _bridge.loadMapAndChallenge(
        mapJson: widget.initialMapJson!,
        challengeJson: widget.initialChallengeJson!,
      );
    } else if (widget.initialProgram != null) {
      _loadMapAndRunProgram();
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

  Future<void> _reloadMapAndChallenge() async {
    if (widget.initialMapJson != null && widget.initialChallengeJson != null) {
      await _bridge.loadMapAndChallenge(
        mapJson: widget.initialMapJson!,
        challengeJson: widget.initialChallengeJson!,
      );
    }
  }

  Future<void> _getGameStatus() async {
    final status = await _bridge.getGameStatus();
    if (status != null) {
      _showStatusDialog('STATUS', 'Game Status', Colors.blue, status);
    }
  }

  Future<void> _zoomInWebView() async {
    final newZoom = (_webViewZoom + _zoomStep).clamp(_minZoom, _maxZoom);
    if (newZoom != _webViewZoom) {
      setState(() {
        _webViewZoom = newZoom;
      });
      await _applyWebViewZoom(newZoom);
    }
  }

  Future<void> _zoomOutWebView() async {
    final newZoom = (_webViewZoom - _zoomStep).clamp(_minZoom, _maxZoom);
    if (newZoom != _webViewZoom) {
      setState(() {
        _webViewZoom = newZoom;
      });
      await _applyWebViewZoom(newZoom);
    }
  }

  Future<void> _applyWebViewZoom(double zoom) async {
    try {
      final zoomStr = zoom.toStringAsFixed(2);
      await _controller.runJavaScript('''
        (function() {
          // Method 1: Sử dụng CSS zoom property (hỗ trợ tốt nhất)
          var body = document.body;
          var html = document.documentElement;
          if (body) {
            body.style.zoom = $zoomStr;
          }
          if (html) {
            html.style.zoom = $zoomStr;
          }
          
          // Method 2: Sử dụng CSS transform scale (fallback)
          var gameContainer = document.getElementById('game-container') || 
                              document.querySelector('canvas')?.parentElement ||
                              body;
          if (gameContainer && !gameContainer.style.zoom) {
            gameContainer.style.transform = 'scale(' + $zoomStr + ')';
            gameContainer.style.transformOrigin = 'top left';
          }
        })();
      ''');
      debugPrint('🔍 WebView zoom applied: $zoomStr');
    } catch (e) {
      debugPrint('❌ Error applying WebView zoom: $e');
    }
  }

  Widget _buildBodyOnly() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('phaser.loading'.tr()),
              ],
            ),
          ),
        // Zoom controls overlay
        if (_isGameReady)
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4B5563), // match CSS color
                  elevation: 3,
                  shape: const CircleBorder(),
                  onPressed: _zoomInWebView,
                  tooltip: 'phaser.zoomIn'.tr(),
                  child: const Icon(Icons.zoom_in, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4B5563), // match CSS color
                  elevation: 3,
                  shape: const CircleBorder(),
                  onPressed: _zoomOutWebView,
                  tooltip: 'phaser.zoomOut'.tr(),
                  child: const Icon(Icons.zoom_out, color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBodyOnly();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('phaser.title'.tr()),
        actions: [
          if (_isGameReady &&
              widget.initialMapJson != null &&
              widget.initialChallengeJson != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reloadMapAndChallenge,
              tooltip: 'phaser.reloadMap'.tr(),
            ),
          if (_isGameReady) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomInWebView,
              tooltip: 'phaser.zoomIn'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOutWebView,
              tooltip: 'phaser.zoomOut'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle),
              onPressed: _runProgram,
              tooltip: 'phaser.runProgram'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _resumeGame,
              tooltip: 'phaser.resume'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _pauseGame,
              tooltip: 'phaser.pause'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetGame,
              tooltip: 'phaser.reset'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _getGameStatus,
              tooltip: 'phaser.status'.tr(),
            ),
          ],
        ],
      ),
      body: _buildBodyOnly(),
      floatingActionButton: _isGameReady
          ? Column(
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
            )
          : null,
    );
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}

