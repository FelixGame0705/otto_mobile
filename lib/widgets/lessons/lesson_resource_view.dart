import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LessonResourceView extends StatefulWidget {
  final String url;
  const LessonResourceView({super.key, required this.url});

  @override
  State<LessonResourceView> createState() => _LessonResourceViewState();
}

class _LessonResourceViewState extends State<LessonResourceView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}


