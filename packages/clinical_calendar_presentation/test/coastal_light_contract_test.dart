import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const coastalLight = CoastalLightThemeBundle();

  test('Coastal Light is one complete independently owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [coastalLight]);

    expect(coastalLight.id, coastalCalmThemeId);
    expect(coastalLight.metadata.displayName, 'Coastal Light');
    expect(coastalLight.standardPresentation, isA<CoastalLightVisualTheme>());
    expect(coastalLight.shellRenderer, isA<CoastalLightShellRenderer>());
    expect(coastalLight.frame.sourceSize, const Size(1536, 1024));
    expect(
      coastalLight.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(
      coastalLight.frame.assetPaths,
      containsAll([coastalLightFrameAsset, coastalLightLandscapeChassisAsset]),
    );
    expect(coastalLight.gallery.swatches, hasLength(5));
    expect(coastalLight.marks.marks, hasLength(9));
    expect(coastalLight.helpGuide.calendarStates, hasLength(5));
    expect(
      coastalLight.helpGuide.calendarStates,
      everyElement(
        isA<CalendarStateGuide>()
            .having((state) => state.nonColorCue, 'non-color cue', isNotEmpty)
            .having(
              (state) => state.enhancedBehavior,
              'Enhanced behavior',
              isNotEmpty,
            ),
      ),
    );

    final standard = coastalLight.standardPresentation.createThemeData();
    expect(standard.colorScheme.secondary, CoastalLightColors.workMachinery);
    final additive = standard.extension<ClinicalCalendarAdditiveColors>()!;
    expect(additive.completed, CoastalLightColors.completed);
    expect(additive.unscheduled, CoastalLightColors.unscheduled);
    expect(additive.overTarget, CoastalLightColors.overTarget);
    expect(additive.today, CoastalLightColors.today);

    final enhanced = coastalLight.standardPresentation.createThemeData(
      enhancedAccessibility: true,
    );
    expect(enhanced.colorScheme.secondary, const Color(0xFF214F6A));
    expect(
      enhanced
          .extension<ClinicalCalendarAccessibilityTokens>()!
          .decorationOpacity,
      0,
    );
    expect(
      enhanced.inputDecorationTheme.enabledBorder,
      isA<OutlineInputBorder>().having(
        (border) => border.borderSide.color,
        'Enhanced control border',
        const Color(0xFF4F6669),
      ),
    );
    expect(
      enhanced.inputDecorationTheme.focusedBorder,
      isA<OutlineInputBorder>().having(
        (border) => border.borderSide.color,
        'Enhanced focus border',
        const Color(0xFF7E281F),
      ),
    );
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        coastalCalmThemeId,
      ),
      same(coastalLight),
    );
  });
}
