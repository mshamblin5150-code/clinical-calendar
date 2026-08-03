/// Public application-layer API. Outer packages implement these ports; domain
/// and application code never import their implementations.
library;

export 'src/application_dependencies.dart';
export 'src/ports.dart';
