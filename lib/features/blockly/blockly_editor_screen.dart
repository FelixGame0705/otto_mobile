
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
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _newWorkspace() async {
    await _bridge?.importWorkspace('<xml xmlns="https://developers.google.com/blockly/xml"></xml>');
  }

  Future<void> _importWorkspace() async {
    final map = await _storage.importFromFile();
    if (map == null) return;
    final xml = map['__xml'] as String?; // optional embedding
    if (xml != null) await _bridge?.importWorkspace(xml);
  }

  Future<void> _exportJson() async {
    if (_compiledProgram == null) return;
    await _storage.exportToFile(_compiledProgram!);
  }

  Future<void> _savePrefs() async {
    if (_compiledProgram == null) return;
    final data = {
      ..._compiledProgram!,
      if (_lastXml != null) '__xml': _lastXml,
    };
    await _storage.saveToPrefs(data);
  }

  Future<void> _loadPrefs() async {
    final loaded = await _storage.loadFromPrefs();
    if (loaded == null) return;
    final xml = loaded['__xml'] as String?;
    if (xml != null) await _bridge?.importWorkspace(xml);
  }

  Future<void> _compile() async {
    await _bridge?.compileNow();
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

  void _switchTab() {
    final controller = DefaultTabController.maybeOf(context);
    if (controller != null) {
      final next = (controller.index + 1) % controller.length;
      controller.animateTo(next);
      setState(() {
        _currentTabIndex = next;
      });
    }
  }

  Widget _buildLeftTabbedPane() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              WebViewWidget(controller: _controller),
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _pythonPreview.isEmpty ? '# Empty\n\nCreate some blocks to see Python code here!' : _pythonPreview,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
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
    return DefaultTabController(
      length: 2,
      initialIndex: _currentTabIndex,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && 
              event.logicalKey == LogicalKeyboardKey.keyP && 
              HardwareKeyboard.instance.isControlPressed) {
            _switchTab();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Blockly Editor'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Blockly'),
                Tab(text: 'Python Preview'),
              ],
            ),
            actions: [
              IconButton(tooltip: 'New', onPressed: _newWorkspace, icon: const Icon(Icons.note_add_outlined)),
              IconButton(tooltip: 'Import', onPressed: _importWorkspace, icon: const Icon(Icons.file_open)),
              IconButton(tooltip: 'Save', onPressed: _savePrefs, icon: const Icon(Icons.save_outlined)),
              IconButton(tooltip: 'Load', onPressed: _loadPrefs, icon: const Icon(Icons.download_outlined)),
              IconButton(tooltip: 'Compile', onPressed: _compile, icon: const Icon(Icons.build_rounded)),
              IconButton(tooltip: 'Export JSON', onPressed: _exportJson, icon: const Icon(Icons.file_download)),
              IconButton(tooltip: 'Send to Phaser', onPressed: _sendToPhaser, icon: const Icon(Icons.send)),
            ],
          ),
          body: Row(
            children: [
              Expanded(child: _buildLeftTabbedPane()),
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
      ),
    );
  }
}


