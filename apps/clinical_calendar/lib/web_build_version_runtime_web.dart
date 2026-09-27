import 'dart:convert';
import 'dart:js_interop';

import 'package:clinical_calendar_sync/web_build_version.dart';
import 'package:web/web.dart' as web;

WebBuildVersionCoordinator createProductionWebBuildVersionCoordinator({
  required int currentBuildNumber,
  required UnsentChangesProbe hasUnsentChanges,
  required Stream<void> unsentChangesDrained,
}) => WebBuildVersionCoordinator(
  currentBuildNumber: currentBuildNumber,
  deployedBuildNumber: _loadDeployedBuildNumber,
  hasUnsentChanges: hasUnsentChanges,
  unsentChangesDrained: unsentChangesDrained,
  reload: () async => web.window.location.reload(),
);

Future<int> _loadDeployedBuildNumber() async {
  final uri = Uri.base
      .resolve('build-id.json')
      .replace(
        queryParameters: {
          'cache_bust': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
  final response = await web.window.fetch(uri.toString().toJS).toDart;
  if (!response.ok) {
    throw StateError('The deployed build id could not be loaded.');
  }
  final source = (await response.text().toDart).toDart;
  final payload = jsonDecode(source);
  final value = switch (payload) {
    final int value => value,
    {'build_number': final int value} => value,
    {'build_number': final String value} => int.tryParse(value),
    _ => null,
  };
  if (value == null || value <= 0) {
    throw const FormatException('The deployed build id is invalid.');
  }
  return value;
}
