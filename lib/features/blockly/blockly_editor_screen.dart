import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:ottobit/core/services/storage_service.dart';
import 'package:ottobit/features/blockly/blockly_bridge.dart';
import 'package:ottobit/features/phaser/phaser_runner_screen.dart';
import 'package:ottobit/features/phaser/phaser_bridge.dart';
import 'package:ottobit/services/challenge_service.dart';
import 'package:ottobit/features/blockly/solution_viewer_screen.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/screens/universal_hex/universal_hex_screen.dart';

class BlocklyEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMapJson;
  final Map<String, dynamic>? initialChallengeJson;
  const BlocklyEditorScreen({
    super.key,
    this.initialMapJson,
    this.initialChallengeJson,
  });

  @override
  State<BlocklyEditorScreen> createState() => _BlocklyEditorScreenState();
}

enum PanelPosition { left, right, top, bottom }

class _BlocklyEditorScreenState extends State<BlocklyEditorScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  BlocklyBridge? _bridge;
  String _pythonPreview = '';
  Map<String, dynamic>? _compiledProgram;
  String? _lastXml;
  final _storage = ProgramStorageService();
  int _lastCompileTick = 0;

  // Right Phaser pane resize
  bool _isDragging = false;
  double _rightPaneWidth = 420.0;
  final double _minRightPaneWidth = 280.0;
  final double _maxRightPaneWidth = 600.0;
  bool _showPythonPreview = false;

  // BLE micro:bit integration
  // BLE service removed - using USB instead
  String _receivedData = '';
  bool _showMicrobitPanel = false;

  // Tutorial
  final GlobalKey _keyToolbarBlockly = GlobalKey();
  final GlobalKey _keyToolbarPython = GlobalKey();
  final GlobalKey _keyToolbarMicrobit = GlobalKey();
  final GlobalKey _keyToolbarSolution = GlobalKey();
  final GlobalKey _keyToolbarNew = GlobalKey();
  final GlobalKey _keyToolbarRestart = GlobalKey();
  final GlobalKey _keyToolbarSend = GlobalKey();
  final GlobalKey _keyLeftPane = GlobalKey();
  final GlobalKey _keyRightPhaser = GlobalKey();
  TutorialCoachMark? _tutorial;
  bool _tutorialQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterFromBlockly',
        onMessageReceived: (msg) {
          // This will be overridden by bridge; keep a log fallback
          debugPrint('JS → Flutter [Blockly]: ${msg.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            debugPrint('Blockly loaded: ' + url);
          },
        ),
      )
      ..loadFlutterAsset('assets/blockly/index.html');

    _bridge = BlocklyBridge(
      controller: _controller,
      onChange:
          ({String? xml, String? python, Map<String, dynamic>? compiled}) {
            if (xml != null) _lastXml = xml;
            if (python != null) _pythonPreview = python;
            if (compiled != null) {
              _compiledProgram = compiled;
              _lastCompileTick = DateTime.now().millisecondsSinceEpoch;
              // Auto-save để Runner có thể load lại khi cần
              final data = {
                ...compiled,
                if (_lastXml != null) '__xml': _lastXml,
                if (widget.initialChallengeJson != null)
                  '__challenge': widget.initialChallengeJson,
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

    // Show tutorial if this is the first challenge of the lesson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueTutorialAfterOrientationStable();
    });
  }

  void _setupBleListeners() {
    // BLE service removed - micro:bit integration disabled
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _newWorkspace() async {
    await _bridge?.importWorkspace(
      '<xml xmlns="https://developers.google.com/blockly/xml"></xml>',
    );
  }

  Future<void> _sendToPhaser() async {
    if (!mounted) return;
    final program = await _compileAndGetProgram();
    if (program == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No program to send. Please create some blocks first.'),
        ),
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
        const SnackBar(
          content: Text('Cannot restart: missing map or challenge data.'),
        ),
      );
    }
  }

  PhaserBridge? _embeddedPhaserBridge;
  final ChallengeService _challengeService = ChallengeService();

  bool get _isFirstChallengeOfLesson {
    final order = widget.initialChallengeJson?["order"];
    return order == 1 || order == "1";
  }

  Future<void> _queueTutorialAfterOrientationStable() async {
    if (!_isFirstChallengeOfLesson) return;
    final lessonId = widget.initialChallengeJson?["lessonId"]?.toString();
    if (lessonId == null || lessonId.isEmpty) return;
    final prefs = await ProgramStorageServiceShared.instance;
    final key = 'tutorial_shown_lesson_' + lessonId;
    final shown = prefs.getBool(key) ?? false;
    if (shown) return;

    _tutorialQueued = true;

    // Wait a bit for any orientation transition/layout settle
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || !_tutorialQueued) return;

    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      _showTutorial();
      _tutorialQueued = false;
      await prefs.setBool(key, true);
    }
  }

  @override
  void didChangeMetrics() {
    if (!_tutorialQueued) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_tutorialQueued) return;
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        _showTutorial();
        _tutorialQueued = false;
      }
    });
  }

  void _showTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'left-pane',
        keyTarget: _keyLeftPane,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
            child: const Text(
              'Khu vực Workspace để kéo thả và lắp ghép các block.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'phaser-pane',
        keyTarget: _keyRightPhaser,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        paddingFocus: 6,
        contents: [
          TargetContent(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
            align: ContentAlign.top,
            child: const Text(
              'Dùng để chạy thử chương trình.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'solution',
        keyTarget: _keyToolbarSolution,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Xem lời giải mẫu để tham khảo cách triển khai.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'blockly',
        keyTarget: _keyToolbarBlockly,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Quay lại khu vực kéo thả Block để tiếp tục chỉnh sửa.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'python',
        keyTarget: _keyToolbarPython,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Xem nhanh mã Python tương ứng với các Block.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'microbit',
        keyTarget: _keyToolbarMicrobit,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Kết nối micro:bit và gửi chương trình để chạy thử.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'new',
        keyTarget: _keyToolbarNew,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Tạo workspace mới trống để bắt đầu lại.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'restart',
        keyTarget: _keyToolbarRestart,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Khởi động lại màn mô phỏng với dữ liệu thử thách ban đầu.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'send',
        keyTarget: _keyToolbarSend,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Gửi chương trình hiện tại sang Phaser Runner để chạy.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.7),
      hideSkip: false,
      textSkip: 'Bỏ qua',
      onFinish: () {},
      onSkip: () {
        return true;
      },
    );
    _tutorial!.show(context: context);
  }

  void _togglePythonPreview() {
    setState(() {
      _showPythonPreview = !_showPythonPreview;
    });
  }

  Future<Map<String, dynamic>?> _compileAndGetProgram() async {
    final int before = _lastCompileTick;
    await _bridge?.compileNow();
    // wait briefly to allow onChange to capture compilation
    await Future.delayed(const Duration(milliseconds: 200));
    if (_compiledProgram != null && _lastCompileTick != before) {
      return _compiledProgram;
    }
    // fallback to persisted copy if compile did not trigger
    final persisted = await _storage.loadFromPrefs();
    return persisted;
  }

  Future<void> _openSolution() async {
    try {
      final challengeId = widget.initialChallengeJson != null
          ? (widget.initialChallengeJson!['id'] as String?)
          : null;
      if (challengeId == null || challengeId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing challenge id to fetch solution.'),
          ),
        );
        return;
      }
      final program = await _challengeService.getChallengeSolution(challengeId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SolutionViewerScreen(program: program, title: 'Solution'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load solution: $e')));
    }
  }

  void _toggleMicrobitPanel() {
    setState(() {
      _showMicrobitPanel = !_showMicrobitPanel;
    });
  }

  Future<void> _sendToMicrobit() async {
    // BLE service removed - micro:bit integration disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('micro:bit integration disabled - use Universal Hex tab instead'),
        backgroundColor: Colors.orange,
      ),
    );
    return;

    try {
      final program = await _compileAndGetProgram();
      if (program == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No program to send. Please create some blocks first.',
            ),
          ),
        );
        return;
      }
      // Convert fresh compiled program to string and send securely
      String programData = program.toString();
      // BLE service removed

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program sent to micro:bit!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send program: $e')));
    }
  }

  Future<void> _openMicrobitConnection() async {
    // MicrobitConnectionScreen removed - using USB instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use Universal Hex tab for micro:bit programming'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
    });
  }

  Widget _buildLeftPane() {
    return Column(
      key: _keyLeftPane,
      children: [
        Expanded(
          child: _showPythonPreview
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _pythonPreview.isEmpty
                        ? '# Empty\n\nCreate some blocks to see Python code here!'
                        : _pythonPreview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
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
                Icons.bluetooth_disabled,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'micro:bit Disabled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                        _receivedData.isEmpty
                            ? 'No data received from micro:bit yet...'
                            : _receivedData,
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
          _rightPaneWidth = (_rightPaneWidth - details.delta.dx).clamp(
            _minRightPaneWidth,
            _maxRightPaneWidth,
          );
        });
      },
      onPanEnd: (_) => setState(() {
        _isDragging = false;
      }),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 8,
          color: _isDragging
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[300],
          child: Center(
            child: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _isDragging
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
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
              tooltip: 'Detect from Image',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.detectCapture),
              icon: const Icon(Icons.photo_camera_back_outlined),
            ),
            IconButton(
              tooltip: 'Show Solution',
              key: _keyToolbarSolution,
              onPressed: _openSolution,
              icon: const Icon(Icons.help_outline),
            ),
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
                color: (!_showPythonPreview && !_showMicrobitPanel)
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              key: _keyToolbarBlockly,
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
                color: _showPythonPreview
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              key: _keyToolbarPython,
            ),
            IconButton(
              tooltip: 'micro:bit Panel',
              onPressed: _toggleMicrobitPanel,
              icon: Icon(
                Icons.bluetooth,
                color: _showMicrobitPanel
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              key: _keyToolbarMicrobit,
            ),
            IconButton(
              tooltip: 'New',
              key: _keyToolbarNew,
              onPressed: _newWorkspace,
              icon: const Icon(Icons.note_add_outlined),
            ),
            IconButton(
              tooltip: 'Restart Scene',
              key: _keyToolbarRestart,
              onPressed: _restartScene,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Send to Phaser',
              key: _keyToolbarSend,
              onPressed: _sendToPhaser,
              icon: const Icon(Icons.send),
            ),
            IconButton(
              tooltip: 'Universal Hex',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UniversalHexScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.usb),
            ),
            if (false) // BLE service removed
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
              key: _keyRightPhaser,
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
