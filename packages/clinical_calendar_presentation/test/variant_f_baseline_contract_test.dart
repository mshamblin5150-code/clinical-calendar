import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final packageRoot =
      Directory.current.path.endsWith('clinical_calendar_presentation')
      ? Directory.current
      : Directory('packages/clinical_calendar_presentation');
  final manifestFile = File(
    '${packageRoot.path}/test/baselines/variant_f_asset_manifest.json',
  );
  final renderRoot = Directory(
    '${packageRoot.path}/test/baselines/variant_f_renders',
  );

  test('Windows and Linux freeze the same valid render matrix', () async {
    final platformRenders = <String, Map<String, File>>{};
    for (final platform in const ['windows', 'linux']) {
      final files = Directory('${renderRoot.path}/$platform')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'));
      platformRenders[platform] = {
        for (final file in files)
          file.uri.pathSegments.last.replaceAll('.png', ''): file,
      };
    }

    expect(platformRenders['windows']!.keys, platformRenders['linux']!.keys);
    expect(platformRenders['windows'], hasLength(14));
    for (final name in platformRenders['windows']!.keys) {
      final dimensions = <(int, int)>[];
      for (final platform in const ['windows', 'linux']) {
        final codec = await ui.instantiateImageCodec(
          await platformRenders[platform]![name]!.readAsBytes(),
        );
        final frame = await codec.getNextFrame();
        dimensions.add((frame.image.width, frame.image.height));
        frame.image.dispose();
        codec.dispose();
      }
      expect(dimensions[0], dimensions[1], reason: name);
    }
  });

  test(
    'protected Variant F raster assets match the pre-catalog manifest',
    () async {
      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final assets = manifest['assets'] as List<dynamic>;

      for (final entry in assets.cast<Map<String, dynamic>>()) {
        final file = File('${packageRoot.path}/${entry['path']}');
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        expect(bytes.length, entry['bytes'], reason: entry['path'] as String);
        expect(sha256.convert(bytes).toString(), entry['sha256']);
        expect(frame.image.width, entry['width']);
        expect(frame.image.height, entry['height']);

        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test('primary frame preserves transparent corners', () async {
    final file = File(
      '${packageRoot.path}/assets/variant_f_raster/panel-nine-slice-v2.png',
    );
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(pixels, isNotNull);

    int alphaAt(int x, int y) =>
        pixels!.getUint8((y * image.width + x) * 4 + 3);
    for (final corner in const [(0, 0), (1535, 0), (0, 1023), (1535, 1023)]) {
      expect(alphaAt(corner.$1, corner.$2), 0, reason: 'corner $corner');
    }

    image.dispose();
    codec.dispose();
  });

  test(
    'nine-slice cuts and safe insets remain bound to the renderer',
    () async {
      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final renderer = manifest['protectedRenderer'] as Map<String, dynamic>;
      final geometry = manifest['primaryFrameGeometry'] as Map<String, dynamic>;
      final bytes = await File(
        '${packageRoot.path}/${renderer['path']}',
      ).readAsBytes();

      expect(sha256.convert(bytes).toString(), renderer['sha256']);
      expect((geometry['cuts'] as List<dynamic>), hasLength(4));
      expect((geometry['safeInsets'] as Map<String, dynamic>).keys, {
        'calendar',
        'placements',
        'planning',
        'status',
      });
    },
  );
}
