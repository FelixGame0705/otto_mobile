import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';

class UniversalHexService {
  static JavascriptRuntime? _runtime;
  
  /// Initialize QuickJS runtime and load the microbit-fs bundle
  static Future<void> initialize() async {
    if (_runtime != null) return;
    
    _runtime = getJavascriptRuntime();
    
    // Polyfill TextEncoder/TextDecoder for QuickJS environments
    const textEncodingPolyfill = r"""
      (function(){
        if (typeof globalThis === 'undefined') { this.globalThis = this; }
        if (typeof TextDecoder === 'undefined') {
          function TextDecoder(encoding){ this.encoding=(encoding||'utf-8').toLowerCase(); }
          TextDecoder.prototype.decode = function(input){
            if (input && input.buffer) { input = new Uint8Array(input.buffer); }
            if (input instanceof ArrayBuffer) { input = new Uint8Array(input); }
            if (typeof input === 'string') return input;
            var arr = (input instanceof Uint8Array) ? input : new Uint8Array(input||[]);
            var str = '';
            for (var i=0;i<arr.length;i++){ str += String.fromCharCode(arr[i]); }
            try { return decodeURIComponent(escape(str)); } catch(e){ return str; }
          };
          globalThis.TextDecoder = TextDecoder;
        }
        if (typeof TextEncoder === 'undefined') {
          function TextEncoder(){}
          TextEncoder.prototype.encode = function(str){
            var utf8=[];
            for (var i=0;i<str.length;i++){
              var charcode=str.charCodeAt(i);
              if (charcode < 0x80) utf8.push(charcode);
              else if (charcode < 0x800) utf8.push(0xC0 | (charcode>>6), 0x80 | (charcode & 0x3F));
              else if (charcode < 0xD800 || charcode >= 0xE000) utf8.push(0xE0 | (charcode>>12), 0x80 | ((charcode>>6) & 0x3F), 0x80 | (charcode & 0x3F));
              else { i++; charcode = 0x10000 + (((charcode & 0x3FF) << 10) | (str.charCodeAt(i) & 0x3FF)); utf8.push(0xF0 | (charcode>>18), 0x80 | ((charcode>>12) & 0x3F), 0x80 | ((charcode>>6) & 0x3F), 0x80 | (charcode & 0x3F)); }
            }
            return new Uint8Array(utf8);
          };
          globalThis.TextEncoder = TextEncoder;
        }
      })();
    """;
    _runtime!.evaluate(textEncodingPolyfill);

    // Load the microbit-fs bundle
    final bundleData = await rootBundle.load('assets/js/mbfs.bundle.js');
    final bundleString = String.fromCharCodes(bundleData.buffer.asUint8List());
    
    // Execute the bundle to load the functions
    _runtime!.evaluate(bundleString);
  }
  
  /// Build Universal Hex from V1 and V2 firmware with Python code
  static Future<String> buildUniversalHex({
    required String v1Hex,
    required String v2Hex,
    required String mainPy,
  }) async {
    if (_runtime == null) {
      await initialize();
    }
    
    try {
      // Call the buildUniversalHex function from the bundle (escape via JSON)
      final js = 'MicrobitFsBundle.buildUniversalHex(' +
          jsonEncode(v1Hex) + ',' +
          jsonEncode(v2Hex) + ',' +
          jsonEncode(mainPy) +
          ')';
      final result = _runtime!.evaluate(js).stringResult;
      return result;
    } catch (e) {
      final msg = e.toString();
      final isUicrError = msg.contains('MicroPython UICR') ||
          msg.contains('regions table') ||
          msg.contains('UICR');
      if (isUicrError) {
        // Fallback: attempt V2-only build by feeding V2 firmware into both slots
        try {
          final jsFallback = 'MicrobitFsBundle.buildUniversalHex(' +
              jsonEncode(v2Hex) + ',' +
              jsonEncode(v2Hex) + ',' +
              jsonEncode(mainPy) +
              ')';
          final fbResult = _runtime!.evaluate(jsFallback).stringResult;
          return fbResult;
        } catch (_) {
          // Ignore and rethrow original error below
        }
      }
      throw Exception('Failed to build Universal Hex: $e');
    }
  }

  /// Convenience: load V1 & V2 firmware from assets and build Universal Hex
  static Future<String> buildUniversalHexFromAssets({
    required String mainPy,
  }) async {
    final v1 = await loadFirmwareHex('v1');
    final v2 = await loadFirmwareHex('v2');
    return buildUniversalHex(v1Hex: v1, v2Hex: v2, mainPy: mainPy);
  }

  /// Build V2-only Hex from V2 firmware with Python code
  static Future<String> buildV2Hex({
    required String v2Hex,
    required String mainPy,
  }) async {
    if (_runtime == null) {
      await initialize();
    }
    // Use universal builder but feed V2 firmware into both slots to avoid requiring V1
    return buildUniversalHex(v1Hex: v2Hex, v2Hex: v2Hex, mainPy: mainPy);
  }

  /// Convenience: Load V2 firmware from assets and build
  static Future<String> buildV2HexFromAssets({
    required String mainPy,
  }) async {
    final v2Hex = await loadFirmwareHex('v2');
    return buildV2Hex(v2Hex: v2Hex, mainPy: mainPy);
  }
  
  /// Validate hex content
  static Future<bool> validateHex(String hex) async {
    if (_runtime == null) {
      await initialize();
    }
    
    try {
      final js = 'MicrobitFsBundle.validateHex(' + jsonEncode(hex) + ')';
      final result = _runtime!.evaluate(js).rawResult;
      
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get estimated Universal Hex size
  static Future<int> getEstimatedSize({
    required String v1Hex,
    required String v2Hex,
    required String mainPy,
  }) async {
    if (_runtime == null) {
      await initialize();
    }
    
    try {
      final js = 'MicrobitFsBundle.getEstimatedSize(' +
          jsonEncode(v1Hex) + ',' +
          jsonEncode(v2Hex) + ',' +
          jsonEncode(mainPy) +
          ')';
      final result = _runtime!.evaluate(js).rawResult;
      
      if (result is num) {
        return result.toInt();
      } else {
        return 1800000; // Default estimate
      }
    } catch (e) {
      return 1800000; // Default estimate
    }
  }

  /// Get estimated V2-only hex size
  static Future<int> getEstimatedSizeV2({
    required String v2Hex,
    required String mainPy,
  }) async {
    if (_runtime == null) {
      await initialize();
    }
    try {
      // Reuse universal estimator with V2 in both slots
      final js = 'MicrobitFsBundle.getEstimatedSize(' +
          jsonEncode(v2Hex) + ',' +
          jsonEncode(v2Hex) + ',' +
          jsonEncode(mainPy) +
          ')';
      final result = _runtime!.evaluate(js).rawResult;
      if (result is num) {
        return result.toInt();
      } else {
        return 900000; // rough default for single target
      }
    } catch (e) {
      return 900000;
    }
  }
  
  /// Flash hex content to micro:bit via USB
  static Future<void> flashHex({
    required String hexContent,
  }) async {
    // USB flashing sẽ được xử lý trực tiếp trong UsbService
    // Method này giữ lại để tương thích với UI
  }
  
  /// Load firmware hex from assets
  static Future<String> loadFirmwareHex(String version) async {
    try {
      final hexData = await rootBundle.load('assets/firmware/micropython-microbit-$version.hex');
      return String.fromCharCodes(hexData.buffer.asUint8List());
    } catch (e) {
      throw Exception('Failed to load firmware $version: $e');
    }
  }
  
  /// Dispose the QuickJS runtime
  static void dispose() {
    _runtime = null;
    _runtime = null;
  }
}

// mock removed; using flutter_js runtime
