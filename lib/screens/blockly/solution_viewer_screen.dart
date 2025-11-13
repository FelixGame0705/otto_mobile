import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SolutionViewerScreen extends StatefulWidget {
  final Map<String, dynamic> program;
  final String? title;
  const SolutionViewerScreen({super.key, required this.program, this.title});

  @override
  State<SolutionViewerScreen> createState() => _SolutionViewerScreenState();
}

class _SolutionViewerScreenState extends State<SolutionViewerScreen> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SolutionFromFlutter',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            if (data['type'] == 'ready') {
              setState(() {
                _ready = true;
              });
              _postProgram();
            }
          } catch (_) {}
        },
      )
      ..loadFlutterAsset('assets/blockly/solution.html');
  }

  Future<void> _postProgram() async {
    if (!_ready) return;
    final jsonStr = jsonEncode(widget.program);
    final js =
        'window.showSolution && window.showSolution(' +
        jsonEncode(jsonStr) +
        ');';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Solution')),
      body: WebViewWidget(controller: _controller),
    );
  }
}

