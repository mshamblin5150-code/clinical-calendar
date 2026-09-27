import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildWebRoot());
}

Widget buildWebRoot() => const _WebUnavailableApplication();

final class _WebUnavailableApplication extends StatelessWidget {
  const _WebUnavailableApplication();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173A5E)),
    ),
    home: const Scaffold(
      key: Key('web-not-available'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Clinical Calendar', style: TextStyle(fontSize: 28)),
              SizedBox(height: 12),
              Text(
                'Web support is not available yet.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
