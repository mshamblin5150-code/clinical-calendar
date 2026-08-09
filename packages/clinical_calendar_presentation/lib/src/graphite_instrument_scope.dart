import 'package:flutter/widgets.dart';

/// Enables Graphite's dense instrument treatment for shared live surfaces.
///
/// The shared widgets continue to own their production data and callbacks; the
/// enclosing Graphite renderer owns only their visual composition.
final class GraphiteInstrumentScope extends InheritedWidget {
  const GraphiteInstrumentScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GraphiteInstrumentScope>() !=
      null;

  @override
  bool updateShouldNotify(GraphiteInstrumentScope oldWidget) => false;
}
