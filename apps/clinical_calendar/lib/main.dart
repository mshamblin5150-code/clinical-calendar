import 'main_web.dart'
    if (dart.library.io) 'main_native.dart'
    as implementation;

export 'main_web.dart' if (dart.library.io) 'main_native.dart';

Future<void> main() => implementation.main();
