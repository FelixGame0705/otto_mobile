import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:ottobit/services/program_storage_service.dart';
import 'package:ottobit/features/blockly/blockly_bridge.dart';
import 'package:ottobit/screens/phaser/phaser_runner_screen.dart';
import 'package:ottobit/features/phaser/phaser_bridge.dart';
import 'package:ottobit/services/challenge_service.dart';
import 'package:ottobit/screens/blockly/solution_viewer_screen.dart';
import 'package:ottobit/screens/universal_hex/universal_hex_screen.dart';
import 'package:ottobit/screens/detect/detect_capture_screen.dart';
import 'package:ottobit/services/socket_service.dart';
import 'package:ottobit/services/room_id_service.dart';
import 'package:ottobit/services/insert_code_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

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
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Random _random = Random();
  static const String _soundAssetPrefix = 'sound/';
  static const List<String> _bgmFiles = [
    'Mario Kart 7 Soundtrack - Main Title Theme.mp3',
    'Toad_s Factory (OST) - Mario Kart Wii.mp3',
    'Delfino Square - Mario Kart DS OST.mp3',
    'Sunshine Airport - Mario Kart 8 Deluxe OST.mp3',
    'Coconut Mall - Mario Kart Wii OST.mp3',
  ];
  BlocklyBridge? _bridge;
  String _pythonPreview = '';
  Map<String, dynamic>? _compiledProgram;
  String? _lastXml;
  final _storage = ProgramStorageService();
  int _lastCompileTick = 0;

  // Challenge mode: 0 = simulation, 1 = upload code
  int get _challengeMode {
    final dynamic raw = widget.initialChallengeJson?['challengeMode'] ?? widget.initialChallengeJson?['mode'];
    if (raw is int) return raw;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return 0;
  }
  bool get _isUploadMode => _challengeMode == 1;

  // Challenge type: 0 = Battery, 1 = Box
  int? get _challengeType {
    final dynamic raw = widget.initialChallengeJson?['challengeType'];
    if (raw is int) return raw;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  // Get HTML file path based on challenge type
  String get _blocklyHtmlPath {
    if (_challengeType == 1) {
      // Box challenge
      return 'assets/blockly/indexBox.html';
    } else {
      // Battery challenge (default) or null
      return 'assets/blockly/indexBattery.html';
    }
  }

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
  Map<String, dynamic>? _latestActionsProgram; // program built from socket actions

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
  final GlobalKey _keyUniversalHex = GlobalKey();
  TutorialCoachMark? _tutorial;
  bool _tutorialQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set orientation immediately
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Also set after first frame to ensure it's applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    
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
            debugPrint('Blockly loaded: $url (challengeType: $_challengeType)');
          },
        ),
      )
      ..loadFlutterAsset(_blocklyHtmlPath);

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

    // Initialize Socket.IO connection
    if (_isUploadMode) {
      _initializeSocketConnection();
      // Start connection monitoring
      _startConnectionMonitoring();
    }

    _playRandomBackgroundMusic();
  }

  void _setupBleListeners() {
    // BLE service removed - micro:bit integration disabled
  }

  Future<void> _playRandomBackgroundMusic() async {
    if (_bgmFiles.isEmpty) return;
    final fileName = _bgmFiles[_random.nextInt(_bgmFiles.length)];
    final assetPath = '$_soundAssetPrefix$fileName';
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.3);
      await _bgmPlayer.play(AssetSource(assetPath));
      debugPrint('🎵 Playing Blockly BGM: $assetPath');
    } catch (e) {
      debugPrint('❌ Failed to play Blockly BGM: $e');
    }
  }

  /// Xử lý bất kỳ event nào từ Socket.IO
  Future<void> _handleAnySocketEvent(String eventName, dynamic data) async {
    try {
      debugPrint('📡 Socket event received: $eventName with data: $data');
      // No toast notifications for generic events
    } catch (e) {
      debugPrint('❌ Error handling socket event: $e');
    }
  }

  /// Xử lý event actions từ Socket.IO
  Future<void> _handleActionsEvent(dynamic data) async {
    try {
      debugPrint('🤖 Handling actions event: $data');
      
      if (data is! Map<String, dynamic>) {
        debugPrint('❌ Invalid actions data format');
        return;
      }

      final actions = data['actions'] as List<dynamic>?;
      if (actions == null || actions.isEmpty) {
        debugPrint('❌ No actions found in data');
        return;
      }
      // No toast preview for actions

      // Kiểm tra PhaserBridge có sẵn sàng không
      if (_embeddedPhaserBridge == null) {
        debugPrint('❌ PhaserBridge not ready yet, cannot execute actions');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Phaser game chưa sẵn sàng, vui lòng thử lại'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Chuyển đổi socket actions -> Phaser program JSON (không hiển thị block)
      final program = _convertSocketActionsToProgram(actions);
      _latestActionsProgram = program; // lưu để dùng nút Simulation ở dialog
      debugPrint('🤖 Converted socket actions to program: ${jsonEncode(program)}');
      // Chạy headless để trình biên dịch trong game xử lý nhanh
      await _embeddedPhaserBridge!.runProgramHeadless(program);
      
    } catch (e) {
      debugPrint('❌ Error handling actions event: $e');
      // No toast on error
    }
  }

  Map<String, dynamic> _convertSocketActionsToProgram(List<dynamic> actions) {
    List<Map<String, dynamic>> toNodes = [];
    for (final a in actions) {
      final String s = a.toString();
      switch (s) {
        case 'forward':
          toNodes.add({'type': 'forward', 'count': 1});
          break;
        case 'turnRight':
          toNodes.add({'type': 'turnRight'});
          break;
        case 'turnLeft':
          toNodes.add({'type': 'turnLeft'});
          break;
        case 'turnBack':
          toNodes.add({'type': 'turnBack'});
          break;
        case 'collectYellow':
          toNodes.add({'type': 'collect', 'color': 'yellow', 'count': 1});
          break;
        case 'collectGreen':
          toNodes.add({'type': 'collect', 'color': 'green', 'count': 1});
          break;
        case 'collectRed':
          toNodes.add({'type': 'collect', 'color': 'red', 'count': 1});
          break;
        default:
          // Unknown action; ignore
          break;
      }
    }
    return {
      'version': '1.0.0',
      'programName': 'socket_actions',
      'actions': toNodes,
    };
  }

  /// Khởi tạo kết nối Socket.IO và join room
  Future<void> _initializeSocketConnection() async {
    try {
      // Lấy room ID từ RoomIdService (sẽ tạo mới nếu chưa có)
      _roomId = _roomIdService.getRoomId();
      debugPrint('Using room ID: $_roomId');

      // Set callback cho event actions
      _socketService.setOnActionsReceived(_handleActionsEvent);
      
      // Lắng nghe tất cả các events từ socket để hiển thị toast
      _socketService.setOnAnyEventReceived(_handleAnySocketEvent);

      // Kiểm tra xem Socket.IO đã connect chưa
      if (_socketService.isConnected) {
        debugPrint('✅ Socket.IO already connected, skipping connection');
        // Cập nhật UI
        if (mounted) {
          setState(() {});
        }
        return;
      }

      // Kết nối tới Socket.IO server với auto-reconnection
      final connected = await _socketService.connect();
      if (connected) {
        debugPrint('Socket.IO connected successfully');
        
        // Join room với ID đã tạo
        final joined = await _socketService.joinRoom(_roomId!);
        if (joined) {
          debugPrint('Successfully joined room: $_roomId');
        } else {
          debugPrint('Failed to join room: $_roomId');
        }
        
        // Cập nhật UI
        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('Failed to connect to Socket.IO server - auto-reconnection will be attempted');
      }
    } catch (e) {
      debugPrint('Error initializing Socket.IO connection: $e');
      // Auto-reconnection sẽ được xử lý bởi SocketService
    }
  }

  @override
  void dispose() {
    // KHÔNG disconnect Socket.IO khi chuyển màn hình
    // Socket.IO sẽ được duy trì để nhận events từ server
    // Chỉ disconnect khi app thực sự đóng (được xử lý ở main.dart)
    
    // Stop connection monitoring
    _connectionMonitorTimer?.cancel();
    
    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
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
  
  // Socket.IO integration
  final SocketService _socketService = SocketService.instance;
  final RoomIdService _roomIdService = RoomIdService.instance;
  String? _roomId;
  Timer? _connectionMonitorTimer;

  bool get _isFirstChallengeOfLesson {
    final order = widget.initialChallengeJson?["order"];
    return order == 1 || order == "1";
  }

  Future<void> _openDetectDialog() async {
    try {
      final detections = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.9,
              height: MediaQuery.of(ctx).size.height * 0.9,
              child: const DetectCaptureScreen(asDialog: true),
            ),
          );
        },
      );
      if (detections == null || detections.isEmpty) return;
      final xml = _detectionsToBlocklyXml(detections);
      final ok = await _bridge?.importWorkspace(xml) ?? false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Imported detected blocks into workspace' : 'Failed to import blocks into workspace')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import detected blocks: $e')),
      );
    }
  }

  String _detectionsToBlocklyXml(List<Map<String, dynamic>> detections) {
    String numberShadow(String name, int value) {
      return '<value name="' + name + '"><block type="math_number"><field name="NUM">' + value.toString() + '</field></block></value>';
    }

    String actionToXml(Map<String, dynamic> a, {String? next}) {
      final cls = (a['class_name'] ?? '').toString();
      final dynamic rawVal = a['value'];
      if (cls == 'move_forward' || cls == 'forward') {
        final count = rawVal is int ? rawVal : int.tryParse((rawVal ?? '').toString()) ?? 1;
        final body = numberShadow('COUNT', count);
        return '<block type="forward">' + body + (next != null ? '<next>' + next + '</next>' : '') + '</block>';
      }
      if (cls == 'collect') {
        final count = rawVal is int ? rawVal : int.tryParse((rawVal ?? '').toString()) ?? 1;
        // Provide explicit default color to be safe
        return '<block type="collect"><field name="COLOR">yellow</field>' + numberShadow('COUNT', count) + (next != null ? '<next>' + next + '</next>' : '') + '</block>';
      }
      if (cls == 'turn_right') {
        return '<block type="turn"><field name="DIR">turnRight</field>' + (next != null ? '<next>' + next + '</next>' : '') + '</block>';
      }
      if (cls == 'turn_left') {
        return '<block type="turn"><field name="DIR">turnLeft</field>' + (next != null ? '<next>' + next + '</next>' : '') + '</block>';
      }
      return next ?? '';
    }

    String? nextXml;
    final buffer = StringBuffer();
    buffer.write('<xml xmlns="https://developers.google.com/blockly/xml">');

    for (int i = detections.length - 1; i >= 0; i--) {
      final item = detections[i];
      final cls = (item['class_name'] ?? '').toString();
      if (cls == 'repeat_start') {
        final count = (item['value'] is int)
            ? item['value'] as int
            : int.tryParse((item['value'] ?? '').toString()) ?? 1;
        final actions = (item['actions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        String? innerNext;
        for (int j = actions.length - 1; j >= 0; j--) {
          innerNext = actionToXml(actions[j], next: innerNext);
        }
        final doXml = innerNext != null
            ? '<statement name="DO">' + innerNext + '</statement>'
            : '<statement name="DO"></statement>';
        final repeatXml = '<block type="repeat_simple">' + numberShadow('COUNT', count) + doXml + (nextXml != null ? '<next>' + nextXml + '</next>' : '') + '</block>';
        nextXml = repeatXml;
      } else if (cls == 'start') {
        final startXml = '<block type="start" deletable="false" movable="true">' + (nextXml != null ? '<next>' + nextXml + '</next>' : '') + '</block>';
        buffer.write(startXml);
        nextXml = null;
      } else {
        nextXml = actionToXml(item, next: nextXml);
      }
    }

    if (nextXml != null && nextXml.isNotEmpty) buffer.write(nextXml);
    buffer.write('</xml>');
    return buffer.toString();
  }

  /// Trigger build and flash from Blockly trong Universal Hex dialog
  void _triggerBuildAndFlashFromBlockly() {
    // Gọi method buildAndFlashFromBlockly thông qua callback
    _buildAndFlashFromBlocklyCallback();
  }

  /// Bắt đầu monitoring connection status
  void _startConnectionMonitoring() {
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Cập nhật UI để reflect connection status
      setState(() {});
      
      // Log connection status for debugging
      if (!_socketService.isConnected) {
        debugPrint('⚠️ Socket.IO connection lost - auto-reconnection in progress');
      }
    });
  }

  /// Callback để build and flash from Blockly
  Future<void> _buildAndFlashFromBlocklyCallback() async {
    try {
      // Lấy Python code từ Blockly program hiện tại
      final program = await _compileAndGetProgram();
      if (program == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No Blockly program available to build from'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Lấy room ID hiện tại
      final roomId = _roomIdService.getRoomId();
      
      // Build Python code từ Blockly program
      final pythonCode = await InsertCodeService.buildMainPyFromLatestBlockly(
        wifiSsid: null, // Có thể lấy từ dialog sau
        wifiPass: null, // Có thể lấy từ dialog sau
        actionsRoomId: roomId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Generated Python code from Blockly program (${pythonCode.length} chars)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Tìm UniversalHexScreen widget và gọi method buildAndFlashFromBlockly
      final universalHexState = _keyUniversalHex.currentState;
      if (universalHexState != null) {
        // Gọi method buildAndFlashFromBlockly
        await (universalHexState as dynamic).buildAndFlashFromBlockly();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Building Universal Hex from Blockly program...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      debugPrint('🤖 Generated Python code: $pythonCode');
      
    } catch (e) {
      debugPrint('❌ Error building from Blockly: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error building from Blockly: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure landscape orientation is maintained when navigating to new challenge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void didChangeMetrics() {
    // Ensure landscape orientation is maintained
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final orientation = MediaQuery.of(context).orientation;
        if (orientation != Orientation.landscape) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      }
    });
    
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


  Future<void> _sendToMicrobit() async {
    // BLE service removed - micro:bit integration disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('micro:bit integration disabled - use Universal Hex tab instead'),
        backgroundColor: Colors.orange,
      ),
    );
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
          title: Row(
            children: [
              const Text('Blockly Editor'),
              const SizedBox(width: 8),
              // Socket.IO connection indicator + room chỉ hiển thị ở upload mode
              if (_isUploadMode)
                Tooltip(
                  message: _socketService.isConnected 
                      ? 'Socket.IO Connected' 
                      : 'Socket.IO Disconnected',
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _socketService.isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Detect from Image',
              onPressed: _openDetectDialog,
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
            // IconButton(
            //   tooltip: 'micro:bit Panel',
            //   onPressed: _toggleMicrobitPanel,
            //   icon: Icon(
            //     Icons.bluetooth,
            //     color: _showMicrobitPanel
            //         ? Theme.of(context).primaryColor
            //         : null,
            //   ),
            //   key: _keyToolbarMicrobit,
            // ),
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
            if (!_isUploadMode)
              IconButton(
                tooltip: 'Send to Phaser',
                key: _keyToolbarSend,
                onPressed: _sendToPhaser,
                icon: const Icon(Icons.send),
              ),
            if (_isUploadMode)
              IconButton(
                tooltip: 'Universal Hex',
                onPressed: _showUniversalHexDialog,
                icon: const Icon(Icons.usb),
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
                getActionsProgram: _isUploadMode ? () => _latestActionsProgram : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog với toàn bộ data từ socket


  /// Hiển thị Universal Hex dialog
  void _showUniversalHexDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header với nút đóng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ba4a),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.usb, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Universal Hex Builder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Build + Flash from Blockly',
                      onPressed: () {
                        // Gọi method buildAndFlashFromBlockly từ UniversalHexScreen
                        _triggerBuildAndFlashFromBlockly();
                      },
                      icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      tooltip: 'Close Universal Hex',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Universal Hex content
              Expanded(
                child: UniversalHexScreen(
                  key: _keyUniversalHex,
                  onBuildFromBlockly: _triggerBuildAndFlashFromBlockly,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
