
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otto_mobile/core/services/storage_service.dart';
import 'package:otto_mobile/features/blockly/blockly_bridge.dart';
import 'package:otto_mobile/features/phaser/phaser_runner_screen.dart';

class BlocklyEditorScreen extends StatefulWidget {
  const BlocklyEditorScreen({super.key});

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
  
  // Drag and drop state
  PanelPosition _panelPosition = PanelPosition.right;
  bool _isDragging = false;
  double _panelSize = 360.0;
  final double _minPanelSize = 200.0;
  final double _maxPanelSize = 500.0;
  bool _isResizingFromDivider = false;

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
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhaserRunnerScreen(initialProgram: program)),
    );
  }

  void _togglePanelPosition() {
    setState(() {
      switch (_panelPosition) {
        case PanelPosition.right:
          _panelPosition = PanelPosition.left;
          break;
        case PanelPosition.left:
          _panelPosition = PanelPosition.top;
          break;
        case PanelPosition.top:
          _panelPosition = PanelPosition.bottom;
          break;
        case PanelPosition.bottom:
          _panelPosition = PanelPosition.right;
          break;
      }
    });
  }

  void _resizePanel(double delta) {
    setState(() {
      // Khi kéo từ thanh chắn, cần đảo ngược hướng delta cho left và top
      double adjustedDelta = delta;
      if (_isResizingFromDivider) {
        if (_panelPosition == PanelPosition.left || _panelPosition == PanelPosition.top) {
          adjustedDelta = -delta;
        }
      }
      _panelSize = (_panelSize + adjustedDelta).clamp(_minPanelSize, _maxPanelSize);
    });
  }

  String _getPositionName() {
    switch (_panelPosition) {
      case PanelPosition.left:
        return 'Left';
      case PanelPosition.right:
        return 'Right';
      case PanelPosition.top:
        return 'Top';
      case PanelPosition.bottom:
        return 'Bottom';
    }
  }

  IconData _getPositionIcon() {
    switch (_panelPosition) {
      case PanelPosition.left:
        return Icons.view_sidebar;
      case PanelPosition.right:
        return Icons.view_sidebar_outlined;
      case PanelPosition.top:
        return Icons.view_agenda;
      case PanelPosition.bottom:
        return Icons.view_agenda_outlined;
    }
  }

  Widget _buildBody() {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildLayout(),
        ),
        // Resize indicator
        if (_isDragging)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Resizing: ${_panelSize.round()}px',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLayout() {
    switch (_panelPosition) {
      case PanelPosition.left:
        return Row(
          key: const ValueKey('left'),
          children: [
            _buildDraggablePanel(),
            _buildDivider(isVertical: false),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        );
      case PanelPosition.right:
        return Row(
          key: const ValueKey('right'),
          children: [
            Expanded(child: WebViewWidget(controller: _controller)),
            _buildDivider(isVertical: false),
            _buildDraggablePanel(),
          ],
        );
      case PanelPosition.top:
        return Column(
          key: const ValueKey('top'),
          children: [
            _buildDraggablePanel(),
            _buildDivider(isVertical: true),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        );
      case PanelPosition.bottom:
        return Column(
          key: const ValueKey('bottom'),
          children: [
            Expanded(child: WebViewWidget(controller: _controller)),
            _buildDivider(isVertical: true),
            _buildDraggablePanel(),
          ],
        );
    }
  }

  Widget _buildDivider({required bool isVertical}) {
    return Tooltip(
      message: 'Drag to resize panel',
      child: GestureDetector(
        onPanStart: (_) => setState(() {
          _isDragging = true;
          _isResizingFromDivider = true;
        }),
        onPanUpdate: (details) {
          if (isVertical) {
            _resizePanel(details.delta.dy);
          } else {
            _resizePanel(details.delta.dx);
          }
        },
        onPanEnd: (_) => setState(() {
          _isDragging = false;
          _isResizingFromDivider = false;
        }),
        child: MouseRegion(
          cursor: isVertical ? SystemMouseCursors.resizeUpDown : SystemMouseCursors.resizeLeftRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isVertical ? double.infinity : 8,
            height: isVertical ? 8 : double.infinity,
            decoration: BoxDecoration(
              color: _isDragging 
                  ? Theme.of(context).primaryColor.withOpacity(0.3) 
                  : Colors.grey[300],
              border: Border.all(
                color: _isDragging 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Container(
                width: isVertical ? 40 : 4,
                height: isVertical ? 4 : 40,
                decoration: BoxDecoration(
                  color: _isDragging 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _isDragging ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePanel() {
    final isVertical = _panelPosition == PanelPosition.top || _panelPosition == PanelPosition.bottom;
    final panelSize = isVertical ? _panelSize : _panelSize;
    
    return Container(
      width: isVertical ? double.infinity : panelSize,
      height: isVertical ? panelSize : double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: _panelPosition == PanelPosition.right ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
          right: _panelPosition == PanelPosition.left ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
          top: _panelPosition == PanelPosition.bottom ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
          bottom: _panelPosition == PanelPosition.top ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Draggable header
          GestureDetector(
            onPanStart: (_) => setState(() {
              _isDragging = true;
              _isResizingFromDivider = false;
            }),
            onPanUpdate: (details) {
              if (isVertical) {
                _resizePanel(details.delta.dy);
              } else {
                _resizePanel(details.delta.dx);
              }
            },
            onPanEnd: (_) => setState(() {
              _isDragging = false;
              _isResizingFromDivider = false;
            }),
            onDoubleTap: _togglePanelPosition,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDragging ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.code,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Python Preview',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Size indicator
                  Text(
                    '${_panelSize.round()}px',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Resize handle
                  Icon(
                    isVertical ? Icons.drag_handle : Icons.drag_indicator,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                _pythonPreview.isEmpty ? '# Empty\n\nCreate some blocks to see Python code here!' : _pythonPreview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
        ],
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
          _togglePanelPosition();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Blockly Editor'),
        actions: [
          IconButton(tooltip: 'New', onPressed: _newWorkspace, icon: const Icon(Icons.note_add_outlined)),
          IconButton(tooltip: 'Import', onPressed: _importWorkspace, icon: const Icon(Icons.file_open)),
          IconButton(tooltip: 'Save', onPressed: _savePrefs, icon: const Icon(Icons.save_outlined)),
          IconButton(tooltip: 'Load', onPressed: _loadPrefs, icon: const Icon(Icons.download_outlined)),
          IconButton(tooltip: 'Compile', onPressed: _compile, icon: const Icon(Icons.build_rounded)),
          IconButton(tooltip: 'Export JSON', onPressed: _exportJson, icon: const Icon(Icons.file_download)),
          IconButton(
            tooltip: 'Toggle Panel Position (${_getPositionName()}) - Ctrl+P', 
            onPressed: _togglePanelPosition, 
            icon: Icon(_getPositionIcon()),
          ),
          IconButton(tooltip: 'Send to Phaser', onPressed: _sendToPhaser, icon: const Icon(Icons.send)),
        ],
      ),
      body: _buildBody(),
      ),
    );
  }
}


