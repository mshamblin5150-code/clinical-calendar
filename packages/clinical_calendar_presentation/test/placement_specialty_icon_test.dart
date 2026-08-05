import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto-assigns common NP, MD, and DO placement names', () {
    expect(
      placementSpecialtyFor('Advanced Health Assessment'),
      PlacementSpecialtyIcon.clinicalAssessment,
    );
    expect(
      placementSpecialtyFor('Billing and Coding'),
      PlacementSpecialtyIcon.billingAndCoding,
    );
    expect(
      placementSpecialtyFor('Adults'),
      PlacementSpecialtyIcon.internalMedicine,
    );
    expect(
      placementSpecialtyFor('Pediatrics'),
      PlacementSpecialtyIcon.pediatrics,
    );
    expect(
      placementSpecialtyFor('Family Practice'),
      PlacementSpecialtyIcon.familyPractice,
    );
    expect(placementSpecialtyFor('OB'), PlacementSpecialtyIcon.womensHealth);
    expect(
      placementSpecialtyFor('Neonatal Intensive Care'),
      PlacementSpecialtyIcon.neonatal,
    );
    expect(
      placementSpecialtyFor('General Surgery'),
      PlacementSpecialtyIcon.surgery,
    );
    expect(
      placementSpecialtyFor('Osteopathic Manipulative Medicine'),
      PlacementSpecialtyIcon.osteopathicManipulativeMedicine,
    );
  });

  test('uses a stable general icon for unfamiliar electives', () {
    expect(
      placementSpecialtyFor('Unlisted Elective'),
      PlacementSpecialtyIcon.generalClinical,
    );
  });
}
