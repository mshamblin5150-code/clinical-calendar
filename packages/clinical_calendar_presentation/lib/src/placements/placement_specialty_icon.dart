import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PlacementSpecialtyIcon {
  clinicalAssessment('clinical-assessment.svg'),
  billingAndCoding('billing-coding.svg'),
  familyPractice('family-practice.svg'),
  internalMedicine('internal-medicine.svg'),
  pediatrics('pediatrics.svg'),
  neonatal('neonatal.svg'),
  womensHealth('womens-health.svg'),
  behavioralHealth('behavioral-health.svg'),
  acuteCare('acute-care.svg'),
  emergencyMedicine('emergency-medicine.svg'),
  surgery('surgery.svg'),
  osteopathicManipulativeMedicine('osteopathic-medicine.svg'),
  geriatrics('geriatrics.svg'),
  generalClinical('general-clinical.svg');

  const PlacementSpecialtyIcon(this.assetName);
  final String assetName;
}

PlacementSpecialtyIcon placementSpecialtyFor(String placementName) {
  final name = placementName.toLowerCase();
  if (name.trim() == 'ob') return PlacementSpecialtyIcon.womensHealth;
  if (_containsAny(name, const [
    'assessment',
    'diagnostic reasoning',
    'physical exam',
  ])) {
    return PlacementSpecialtyIcon.clinicalAssessment;
  }
  if (_containsAny(name, const [
    'billing',
    'coding',
    'reimbursement',
    'practice management',
  ])) {
    return PlacementSpecialtyIcon.billingAndCoding;
  }
  if (_containsAny(name, const ['neonatal', 'newborn', 'nicu'])) {
    return PlacementSpecialtyIcon.neonatal;
  }
  if (_containsAny(name, const ['pediatric', 'children', 'child health'])) {
    return PlacementSpecialtyIcon.pediatrics;
  }
  if (_containsAny(name, const [
    'women',
    ' ob ',
    'ob ',
    ' ob',
    'ob/gyn',
    'obgyn',
    'obstetric',
    'gynecolog',
    'maternal',
    'reproductive health',
    'prenatal',
  ])) {
    return PlacementSpecialtyIcon.womensHealth;
  }
  if (_containsAny(name, const [
    'behavioral',
    'mental health',
    'psychiatr',
    'psych ',
  ])) {
    return PlacementSpecialtyIcon.behavioralHealth;
  }
  if (_containsAny(name, const [
    'osteopathic manipulative',
    'manipulative medicine',
    'omm',
    'omt',
  ])) {
    return PlacementSpecialtyIcon.osteopathicManipulativeMedicine;
  }
  if (_containsAny(name, const ['surgery', 'surgical', 'perioperative'])) {
    return PlacementSpecialtyIcon.surgery;
  }
  if (_containsAny(name, const ['emergency', 'em '])) {
    return PlacementSpecialtyIcon.emergencyMedicine;
  }
  if (_containsAny(name, const [
    'acute',
    'urgent',
    'emergency',
    'critical',
    'intensive care',
    'icu',
  ])) {
    return PlacementSpecialtyIcon.acuteCare;
  }
  if (_containsAny(name, const ['geriatric', 'older adult', 'senior'])) {
    return PlacementSpecialtyIcon.geriatrics;
  }
  if (_containsAny(name, const [
    'internal medicine',
    'adults',
    'adult health',
    'adult medicine',
    'hospitalist',
    'adult-gerontology primary',
  ])) {
    return PlacementSpecialtyIcon.internalMedicine;
  }
  if (_containsAny(name, const [
    'family',
    'primary care',
    'community health',
  ])) {
    return PlacementSpecialtyIcon.familyPractice;
  }
  return PlacementSpecialtyIcon.generalClinical;
}

bool _containsAny(String value, List<String> candidates) =>
    candidates.any(value.contains);

final class PlacementSpecialtyGlyph extends StatelessWidget {
  const PlacementSpecialtyGlyph({
    required this.placementName,
    this.size = 24,
    this.color,
    super.key,
  });

  final String placementName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final specialty = placementSpecialtyFor(placementName);
    return ExcludeSemantics(
      child: SvgPicture.asset(
        'assets/placement_icons/${specialty.assetName}',
        package: 'clinical_calendar_presentation',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color ?? IconTheme.of(context).color ?? Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
