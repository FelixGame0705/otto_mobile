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
    final jsonStr = jsonEncode(_withDerivedVariables(widget.program));
    final js =
        'window.showSolution && window.showSolution(' +
        jsonEncode(jsonStr) +
        ');';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  Map<String, dynamic> _withDerivedVariables(Map<String, dynamic> program) {
    final existing = program['variables'];
    final hasExistingNames = existing is List &&
        existing.any((v) => v is String && v.toString().trim().isNotEmpty);
    if (hasExistingNames) return program;

    final vars = <String>{};

    void collectFromList(List<dynamic>? nodes) {
      if (nodes == null) return;
      for (final raw in nodes) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['type'] == 'repeatRange') {
          final variable = raw['variable'];
          if (variable is String && variable.trim().isNotEmpty) {
            vars.add(variable);
          }
        }
        for (final key in const ['body', 'then', 'else']) {
          final section = raw[key];
          if (section is List) collectFromList(section);
        }
        final thens = raw['thens'];
        if (thens is List) {
          for (final branch in thens) {
            if (branch is List) collectFromList(branch);
          }
        }
      }
    }

    if (existing is List) {
      for (final v in existing) {
        if (v is String && v.trim().isNotEmpty) vars.add(v);
      }
    }

    final actions = program['actions'];
    if (actions is List) collectFromList(actions);
    final functions = program['functions'];
    if (functions is List) {
      for (final fn in functions) {
        if (fn is Map<String, dynamic>) {
          final body = fn['body'];
          if (body is List) collectFromList(body);
        }
      }
    }

    if (vars.isEmpty) return program;
    final enriched = Map<String, dynamic>.from(program);
    enriched['variables'] = vars.toList();
    return enriched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.title ?? 'Solution'), backgroundColor: Colors.white),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

