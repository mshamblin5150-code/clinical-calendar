import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _keyboardTraversalLimit = 200;

Future<void> focusWithKeyboard(WidgetTester tester, Finder control) async {
  final target = control.evaluate().single;
  for (var attempt = 0; attempt < _keyboardTraversalLimit; attempt += 1) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus?.context as Element?;
    var reached = identical(focused, target);
    focused?.visitAncestorElements((ancestor) {
      reached = identical(ancestor, target);
      return !reached;
    });
    if (reached) return;
  }
  fail(
    'Keyboard traversal did not reach '
    '${control.describeMatch(Plurality.one)}.',
  );
}
