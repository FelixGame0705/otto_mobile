import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ottobit/utils/constants.dart';
import 'dart:io' show Platform;

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String returnUrl;
  final String cancelUrl;
  final int? amount;
  final String? description;
  const PaymentWebViewScreen({super.key, required this.paymentUrl, required this.returnUrl, required this.cancelUrl, this.amount, this.description});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  List<_BankApp> _bankApps = [];

  @override
  void initState() {
    super.initState();
    _latestReturnUrl = widget.returnUrl;
    _latestCancelUrl = widget.cancelUrl;
    _latestAmount = widget.amount;
    _latestDescription = widget.description;
    _latestPaymentUrl = widget.paymentUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _loading = true),
          onPageFinished: (url) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(widget.returnUrl)) {
              Navigator.of(context).pop({'result': 'success', 'url': url});
              return NavigationDecision.prevent;
            }
            if (url.startsWith(widget.cancelUrl)) {
              Navigator.of(context).pop({'result': 'cancel', 'url': url});
              return NavigationDecision.prevent;
            }
            final uri = Uri.parse(url);
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              // Attempt to open deep link (e.g., banking app)
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    _fetchBankApps();
  }

  Future<void> _fetchBankApps() async {
    try {
      final endpoint = Platform.isAndroid
          ? 'https://api.vietqr.io/v2/android-app-deeplinks'
          : 'https://api.vietqr.io/v2/ios-app-deeplinks';
      final resp = await http.get(Uri.parse(endpoint));
      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        final apps = (jsonMap['apps'] as List<dynamic>? ?? [])
            .map((e) => _BankApp.fromJson(e as Map<String, dynamic>))
            .where((e) => e.deeplink.startsWith('http'))
            .toList();
        if (mounted) setState(() => _bankApps = apps);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWidth = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán PayOS'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.loadRequest(Uri.parse(widget.paymentUrl));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          if (isMobileWidth && _bankApps.isNotEmpty)
            Container(
              decoration: const BoxDecoration(color: Color(0xFFF7FAFC), border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Chọn app ngân hàng để thanh toán nhanh:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bankApps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final app = _bankApps[i];
                        return InkWell(
                          onTap: () {
                            final uri = _buildDeepLink(app.deeplink);
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(app.appLogo, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    app.appName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Tải lại nếu không thấy App thanh toán', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankApp {
  final String appId;
  final String appLogo;
  final String appName;
  final String deeplink;
  _BankApp({required this.appId, required this.appLogo, required this.appName, required this.deeplink});
  factory _BankApp.fromJson(Map<String, dynamic> json) => _BankApp(
        appId: (json['appId'] ?? '').toString(),
        appLogo: (json['appLogo'] ?? '').toString(),
        appName: (json['appName'] ?? '').toString().replaceAll('\u200e', ''),
        deeplink: (json['deeplink'] ?? '').toString(),
      );
}

Uri _appendQuery(Uri base, Map<String, String?> params) {
  final filtered = Map<String, String?>.from(params)..removeWhere((key, value) => value == null || value.isEmpty);
  final qp = Map<String, String>.from(base.queryParameters)..addAll(filtered.cast<String, String>());
  return base.replace(queryParameters: qp);
}

Uri _buildDeepLink(String deeplink) {
  Uri base = Uri.parse(deeplink);
  // Common params PayOS/VietQR deeplink might accept: amount, description, returnUrl, cancelUrl
  // VietQR commonly uses: am (amount), tn (note), redirect_url (callback), ba (bank account), bn (beneficiary name)
  final params = <String, String?>{
    'am': _latestAmount?.toString(),
    'tn': _latestDescription,
    'redirect_url': _latestReturnUrl ?? _latestCancelUrl ?? _latestPaymentUrl,
    'ba': (AppConstants.vietqrBankAccount.isNotEmpty) ? AppConstants.vietqrBankAccount : null,
    'bn': (AppConstants.vietqrBankName.isNotEmpty) ? AppConstants.vietqrBankName : null,
  };
  return _appendQuery(base, params);
}

// Store latest context values for deeplink build
String? _latestReturnUrl;
String? _latestCancelUrl;
int? _latestAmount;
String? _latestDescription;
String? _latestPaymentUrl;


