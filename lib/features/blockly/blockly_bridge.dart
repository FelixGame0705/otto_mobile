import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef BlocklyChangeCallback = void Function({String? xml, String? python, Map<String, dynamic>? compiled});

class BlocklyBridge {
  final WebViewController controller;
  final BlocklyChangeCallback onChange;

  const BlocklyBridge({required this.controller, required this.onChange});

  void registerInboundChannel() {
    controller.addJavaScriptChannel('FlutterFromBlockly', onMessageReceived: (message) {
      try {
        final data = jsonDecode(message.message) as Map<String, dynamic>;
        final type = data['type'];
        if (type == 'workspace_change') {
          onChange(xml: data['xml'] as String?);
        } else if (type == 'python_preview') {
          onChange(python: data['python'] as String?);
        } else if (type == 'compiled_program') {
          onChange(compiled: (data['payload'] as Map?)?.cast<String, dynamic>());
        } else {
          debugPrint('Unknown Blockly message: ' + message.message);
        }
      } catch (e) {
        debugPrint('Failed to parse Blockly message: ${message.message}');
      }
    });
  }

  Future<bool> importWorkspace(String xml) async {
    final js = 'window.importWorkspace && window.importWorkspace(' + jsonEncode(xml) + ')';
    try {
      final result = await controller.runJavaScriptReturningResult(js);
      // Some webviews double-encode results; handle both
      Map<String, dynamic>? map;
      if (result is String) {
        try {
          map = jsonDecode(result) as Map<String, dynamic>;
        } catch (_) {
          // Sometimes result itself is quoted JSON string, try decode twice
          final once = jsonDecode(result);
          if (once is String) {
            map = jsonDecode(once) as Map<String, dynamic>;
          }
        }
      } else if (result is Map) {
        map = result.cast<String, dynamic>();
      }
      if (map != null) {
        return map['ok'] == true;
      }
      return true;
    } catch (e) {
      debugPrint('importWorkspace failed: $e');
      return false;
    }
  }

  Future<String?> getWorkspaceXml() async {
    final res = await controller.runJavaScriptReturningResult('''
      (function(){
        if (!window.getWorkspaceXml) return null;
        try { return JSON.stringify({ ok: true, xml: window.getWorkspaceXml() }); }
        catch(e){ return JSON.stringify({ ok: false }); }
      })();
    ''');
    if (res is String) {
      try {
        final map = jsonDecode(res) as Map<String, dynamic>;
        if (map['ok'] == true) return map['xml'] as String?;
      } catch (_) {}
    }
    return null;
  }

  Future<void> compileNow() async {
    await controller.runJavaScript('window.compileNow && window.compileNow();');
  }
}


