
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otto_mobile/core/services/storage_service.dart';
import 'package:otto_mobile/features/blockly/blockly_bridge.dart';
import 'package:otto_mobile/features/phaser/phaser_runner_screen.dart';
import 'package:otto_mobile/features/phaser/phaser_bridge.dart';

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

  PhaserBridge? _embeddedPhaserBridge;

  void _togglePythonPreview() {
    setState(() {
      _showPythonPreview = !_showPythonPreview;
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
            : WebViewWidget(controller: _controller),
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
                });
              },
              icon: Icon(
                Icons.view_module,
                color: !_showPythonPreview ? Theme.of(context).primaryColor : null,
              ),
            ),
            IconButton(
              tooltip: 'Python Preview',
              onPressed: () {
                setState(() {
                  _showPythonPreview = true;
                });
              },
              icon: Icon(
                Icons.code,
                color: _showPythonPreview ? Theme.of(context).primaryColor : null,
              ),
            ),
            IconButton(tooltip: 'New', onPressed: _newWorkspace, icon: const Icon(Icons.note_add_outlined)),
            IconButton(tooltip: 'Send to Phaser', onPressed: _sendToPhaser, icon: const Icon(Icons.send)),
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


