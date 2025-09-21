
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otto_mobile/core/services/storage_service.dart';
import 'package:otto_mobile/features/blockly/blockly_bridge.dart';
import 'package:otto_mobile/features/phaser/phaser_runner_screen.dart';
import 'package:otto_mobile/features/phaser/phaser_bridge.dart';
import 'package:otto_mobile/services/microbit_ble_service.dart';
import 'package:otto_mobile/screens/microbit/microbit_connection_screen.dart';

class BlocklyEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMapJson;
  final Map<String, dynamic>? initialChallengeJson;
  const BlocklyEditorScreen({super.key, this.initialMapJson, this.initialChallengeJson});

  @override
  State<BlocklyEditorScreen> createState() => _BlocklyEditorScreenState();
}

enum PanelPosition { left, right, top, bottom }

class _BlocklyEditorScreenState extends State<BlocklyEditorScreen> {
  late final WebViewController _controller;
  BlocklyBridge? _bridge;
  String _pythonPreview = '';
  Map<String, dynamic>? _compiledProgram;
  String? _lastXml;
  final _storage = ProgramStorageService();
  
  // Right Phaser pane resize
  bool _isDragging = false;
  double _rightPaneWidth = 420.0;
  final double _minRightPaneWidth = 280.0;
  final double _maxRightPaneWidth = 600.0;
  bool _showPythonPreview = false;

  // BLE micro:bit integration
  final MicrobitBleService _bleService = MicrobitBleService();
  String _receivedData = '';
  bool _showMicrobitPanel = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterFromBlockly', onMessageReceived: (msg) {
        // This will be overridden by bridge; keep a log fallback
        debugPrint('JS → Flutter [Blockly]: ${msg.message}');
      })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (url) async {
        debugPrint('Blockly loaded: ' + url);
      }))
      ..loadFlutterAsset('assets/blockly/index.html');

    _bridge = BlocklyBridge(
      controller: _controller,
      onChange: ({String? xml, String? python, Map<String, dynamic>? compiled}) {
        if (xml != null) _lastXml = xml;
        if (python != null) _pythonPreview = python;
        if (compiled != null) {
          _compiledProgram = compiled;
          // Auto-save để Runner có thể load lại khi cần
          final data = {
            ...compiled,
            if (_lastXml != null) '__xml': _lastXml,
          };
          _storage.saveToPrefs(data);
        }
        setState(() {});
      },
    );
    
    // Đăng ký JavaScript channel để nhận messages từ Blockly
    _bridge?.registerInboundChannel();

    // Setup BLE listeners
    _setupBleListeners();
  }

  void _setupBleListeners() {
    // Listen for received data from micro:bit
    _bleService.receivedDataStream.listen((data) {
      setState(() {
        _receivedData += data;
      });
    });

    // Listen for connection state changes
    _bleService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _newWorkspace() async {
    await _bridge?.importWorkspace('<xml xmlns="https://developers.google.com/blockly/xml"></xml>');
  }


  Future<void> _sendToPhaser() async {
    if (!mounted) return;
    var program = _compiledProgram;
    
    // Nếu chưa có compiled program, thử compile trước
    if (program == null) {
      await _bridge?.compileNow();
      await Future.delayed(const Duration(milliseconds: 200));
      program = _compiledProgram ?? await _storage.loadFromPrefs(); // fallback từ prefs
    }
    
    if (program == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No program to send. Please create some blocks first.')),
      );
      return;
    }
    // Gửi vào Phaser embedded nếu có
    _embeddedPhaserBridge?.runProgram(program);
  }

  Future<void> _restartScene() async {
    if (!mounted) return;
    
    if (widget.initialMapJson != null && widget.initialChallengeJson != null) {
      _embeddedPhaserBridge?.restartScene(
        mapJson: widget.initialMapJson!,
        challengeJson: widget.initialChallengeJson!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot restart: missing map or challenge data.')),
      );
    }
  }

  PhaserBridge? _embeddedPhaserBridge;

  void _togglePythonPreview() {
    setState(() {
      _showPythonPreview = !_showPythonPreview;
    });
  }

  void _toggleMicrobitPanel() {
    setState(() {
      _showMicrobitPanel = !_showMicrobitPanel;
    });
  }

  Future<void> _sendToMicrobit() async {
    if (!_bleService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to micro:bit. Please connect first.')),
      );
      return;
    }

    if (_compiledProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No program to send. Please create some blocks first.')),
      );
      return;
    }

    try {
      // Convert compiled program to string and send securely
      String programData = _compiledProgram.toString();
      await _bleService.sendDataSecurely('PROGRAM:$programData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program sent to micro:bit!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send program: $e')),
      );
    }
  }

  Future<void> _openMicrobitConnection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MicrobitConnectionScreen(),
      ),
    );
    
    // Refresh connection state after returning
    if (mounted) {
      setState(() {});
    }
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
    });
  }

  Widget _buildLeftPane() {
    return Column(
      children: [
        Expanded(
          child: _showPythonPreview 
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _pythonPreview.isEmpty ? '# Empty\n\nCreate some blocks to see Python code here!' : _pythonPreview,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              )
            : _showMicrobitPanel
              ? _buildMicrobitPanel()
              : WebViewWidget(controller: _controller),
        ),
      ],
    );
  }

  Widget _buildMicrobitPanel() {
    return Column(
      children: [
        // Connection status header
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Icon(
                _bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: _bleService.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _bleService.isConnected ? 'micro:bit Connected' : 'micro:bit Disconnected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _bleService.isConnected ? Colors.green : Colors.red,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _openMicrobitConnection,
                icon: const Icon(Icons.settings),
                tooltip: 'Connection Settings',
              ),
            ],
          ),
        ),
        
        // Received data section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Received Data',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _clearReceivedData,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear Data',
                        ),
                        IconButton(
                          onPressed: _sendToMicrobit,
                          icon: const Icon(Icons.send),
                          tooltip: 'Send Program to micro:bit',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[50],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _receivedData.isEmpty ? 'No data received from micro:bit yet...' : _receivedData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleDivider() {
    return GestureDetector(
      onPanStart: (_) => setState(() {
        _isDragging = true;
      }),
      onPanUpdate: (details) {
        setState(() {
          _rightPaneWidth = (_rightPaneWidth - details.delta.dx).clamp(_minRightPaneWidth, _maxRightPaneWidth);
        });
      },
      onPanEnd: (_) => setState(() {
        _isDragging = false;
      }),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 8,
          color: _isDragging ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.grey[300],
          child: Center(
            child: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _isDragging ? Theme.of(context).primaryColor : Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && 
            event.logicalKey == LogicalKeyboardKey.keyP && 
            HardwareKeyboard.instance.isControlPressed) {
          _togglePythonPreview();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blockly Editor'),
          actions: [
            IconButton(
              tooltip: 'Blockly',
              onPressed: () {
                setState(() {
                  _showPythonPreview = false;
                  _showMicrobitPanel = false;
                });
              },
              icon: Icon(
                Icons.view_module,
                color: (!_showPythonPreview && !_showMicrobitPanel) ? Theme.of(context).primaryColor : null,
              ),
            ),
            IconButton(
              tooltip: 'Python Preview',
              onPressed: () {
                setState(() {
                  _showPythonPreview = true;
                  _showMicrobitPanel = false;
                });
              },
              icon: Icon(
                Icons.code,
                color: _showPythonPreview ? Theme.of(context).primaryColor : null,
              ),
            ),
            IconButton(
              tooltip: 'micro:bit Panel',
              onPressed: _toggleMicrobitPanel,
              icon: Icon(
                Icons.bluetooth,
                color: _showMicrobitPanel ? Theme.of(context).primaryColor : null,
              ),
            ),
            IconButton(tooltip: 'New', onPressed: _newWorkspace, icon: const Icon(Icons.note_add_outlined)),
            IconButton(tooltip: 'Restart Scene', onPressed: _restartScene, icon: const Icon(Icons.refresh)),
            IconButton(tooltip: 'Send to Phaser', onPressed: _sendToPhaser, icon: const Icon(Icons.send)),
            if (_bleService.isConnected)
              IconButton(
                tooltip: 'Send to micro:bit', 
                onPressed: _sendToMicrobit, 
                icon: const Icon(Icons.bluetooth_connected),
              ),
          ],
        ),
        body: Row(
          children: [
            Expanded(child: _buildLeftPane()),
            _buildMiddleDivider(),
            Container(
              width: _rightPaneWidth,
              color: Theme.of(context).cardColor,
              child: PhaserRunnerScreen(
                embedded: true,
                onBridgeReady: (b) {
                  _embeddedPhaserBridge = b;
                },
                initialMapJson: widget.initialMapJson,
                initialChallengeJson: widget.initialChallengeJson,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


