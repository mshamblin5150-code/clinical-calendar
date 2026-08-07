import 'package:flutter/material.dart';

/// Terminal presentation recovery that constructs no theme assets, shell,
/// Calendar content, or Student data.
final class CodeOnlyPresentationRecoveryApplication extends StatelessWidget {
  const CodeOnlyPresentationRecoveryApplication({
    required this.surfaceKey,
    required this.icon,
    required this.title,
    required this.guidance,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
    super.key,
  });

  final Key surfaceKey;
  final IconData icon;
  final String title;
  final String guidance;
  final String actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1013),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF37D6B4),
        onPrimary: Color(0xFF06251E),
        surface: Color(0xFF151A1F),
        onSurface: Color(0xFFF4F6F7),
      ),
    ),
    home: Scaffold(
      key: surfaceKey,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(guidance, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  key: actionKey,
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
