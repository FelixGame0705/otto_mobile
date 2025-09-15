import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PhaserBridge {
  final WebViewController controller;

  const PhaserBridge(this.controller);

  void registerInboundChannel() {
    controller.addJavaScriptChannel('FlutterFromPhaser', onMessageReceived: (message) {
      debugPrint('JS → Flutter [Phaser]: ${message.message}');
    });
  }

  Future<void> sendProgramToPhaser(Map<String, dynamic> program) async {
    final msg = {'type': 'compiled', 'payload': program};
    final js = '''
      (function(){
        var msg = ${jsonEncode({'type':'compiled','payload': program})};
        try { console.log('[Flutter] sending program to Phaser (PhaserChannel):', msg); } catch(e){}
        var ok = false;
        try {
          if (window.PhaserChannel && typeof window.PhaserChannel.postMessage === 'function') {
            window.PhaserChannel.postMessage(JSON.stringify(msg));
            ok = true;
          }
        } catch(e) { try { console.error('PhaserChannel.postMessage error', e); } catch(_){} }

        if (!ok && typeof window.receiveFromFlutter === 'function') {
          try { window.receiveFromFlutter(msg); ok = true; }
          catch(e){ try { console.error('receiveFromFlutter error', e); } catch(_){} }
        }
        if (!ok) {
          try {
            window.dispatchEvent(new CustomEvent('OttobitProgram', { detail: msg }));
            console.log('[Flutter] dispatched OttobitProgram');
          } catch(e) { try { console.error('dispatchEvent error', e); } catch(_){} }
        }
      })();
    ''';
    debugPrint('Flutter → JS [sendProgramToPhaser] ${program['programName'] ?? ''}');
    await controller.runJavaScript(js);
  }
}
