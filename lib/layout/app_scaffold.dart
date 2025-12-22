import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget child;
  final bool centerTitle;
  final bool showAppBar;
  final List<Color>? gradientColors;
  final Alignment? alignment;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.child,
    this.centerTitle = false,
    this.showAppBar = true,
    this.gradientColors,
    this.alignment = Alignment.topCenter,
    this.backgroundColor = const Color(0xFF00ba4a),
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              centerTitle: centerTitle,
              actions: actions,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? const [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: alignment ?? Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
