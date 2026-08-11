import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';
import '../coastal_light_theme.dart';
import '../theme_contract.dart';

typedef AcademicAssignmentSave =
    Future<void> Function({
      required String title,
      required String course,
      required LocalDate dueDate,
      required AcademicAssignmentStatus status,
    });

final class AcademicAssignmentCalendarWorkspace extends StatelessWidget {
  const AcademicAssignmentCalendarWorkspace({
    required this.themeId,
    required this.calendar,
    required this.onAddAssignment,
    super.key,
  });

  final String themeId;
  final Widget calendar;
  final VoidCallback onAddAssignment;

  @override
  Widget build(BuildContext context) {
    if (!_academicAssignmentThemeIds.contains(themeId)) return calendar;
    final addButton = switch (themeId) {
      graphiteThemeId => _GraphiteAssignmentControlHousing(
        onPressed: onAddAssignment,
      ),
      federationClassicThemeId => _FederationClassicAssignmentControlHousing(
        onPressed: onAddAssignment,
      ),
      federation2399ThemeId => _Federation2399AssignmentControlHousing(
        onPressed: onAddAssignment,
      ),
      coastalCalmThemeId => _CoastalLightAssignmentControlHousing(
        onPressed: onAddAssignment,
      ),
      _ => Align(
        alignment: AlignmentDirectional.centerEnd,
        widthFactor: 1,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: FilledButton.icon(
            key: const Key('add-academic-assignment'),
            onPressed: onAddAssignment,
            icon: const Icon(Icons.assignment_add),
            label: const Text('Add Assignment'),
          ),
        ),
      ),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return Stack(
            fit: StackFit.expand,
            children: [
              calendar,
              PositionedDirectional(end: 8, bottom: 8, child: addButton),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            addButton,
            Flexible(fit: FlexFit.loose, child: calendar),
          ],
        );
      },
    );
  }
}

final class _CoastalLightAssignmentControlHousing extends StatelessWidget {
  const _CoastalLightAssignmentControlHousing({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('coastal-light-assignment-control-housing'),
    constraints: const BoxConstraints(minHeight: 52),
    padding: const EdgeInsets.fromLTRB(5, 4, 8, 4),
    decoration: BoxDecoration(
      color: CoastalLightColors.surface.withValues(alpha: .96),
      border: Border.all(color: CoastalLightColors.insetBorder),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(7),
        bottomLeft: Radius.circular(7),
        bottomRight: Radius.circular(18),
      ),
      boxShadow: [
        BoxShadow(
          color: CoastalLightColors.clinical.withValues(alpha: .18),
          blurRadius: 8,
        ),
      ],
    ),
    child: TextButton.icon(
      key: const Key('add-academic-assignment'),
      onPressed: onPressed,
      icon: const Icon(Icons.assignment_add),
      label: const Text('Add Assignment'),
    ),
  );
}

final class _GraphiteAssignmentControlHousing extends StatelessWidget {
  const _GraphiteAssignmentControlHousing({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('graphite-assignment-control-housing'),
    width: 54,
    height: 54,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF111619).withValues(alpha: .96),
      border: Border(
        left: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
        top: const BorderSide(color: Color(0xFF6F7C86)),
        right: const BorderSide(color: Color(0xFF3E4851)),
        bottom: const BorderSide(color: Color(0xFF3E4851)),
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
      ],
    ),
    child: IconButton(
      key: const Key('add-academic-assignment'),
      tooltip: 'Add Academic Assignment',
      onPressed: onPressed,
      icon: const Icon(Icons.assignment_add),
    ),
  );
}

final class _FederationClassicAssignmentControlHousing extends StatelessWidget {
  const _FederationClassicAssignmentControlHousing({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('federation-classic-assignment-control-housing'),
    width: 58,
    height: 58,
    padding: const EdgeInsets.fromLTRB(7, 7, 3, 3),
    decoration: const BoxDecoration(
      color: Color(0xFFF29A72),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
        bottomLeft: Radius.circular(8),
      ),
      boxShadow: [
        BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
      ],
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15101C),
        border: Border.all(color: const Color(0xFFB8A3E0)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: IconButton(
        key: const Key('add-academic-assignment'),
        tooltip: 'Add Academic Assignment',
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: const Icon(Icons.assignment_add),
      ),
    ),
  );
}

final class _Federation2399AssignmentControlHousing extends StatelessWidget {
  const _Federation2399AssignmentControlHousing({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('federation-2399-assignment-control-housing'),
    width: 56,
    height: 56,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF090B12).withValues(alpha: .96),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(4),
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: IconButton(
      key: const Key('add-academic-assignment'),
      tooltip: 'Add Academic Assignment',
      onPressed: onPressed,
      icon: const Icon(Icons.assignment_add),
    ),
  );
}

const _academicAssignmentThemeIds = <String>{
  graphiteThemeId,
  federationClassicThemeId,
  federation2399ThemeId,
  coastalCalmThemeId,
  botanicalStudyThemeId,
  heritageFieldNotesThemeId,
};

final class AcademicAssignmentEditor extends StatefulWidget {
  const AcademicAssignmentEditor({
    required this.onSave,
    required this.onClose,
    this.record,
    this.onDelete,
    super.key,
  });

  final StoredDomainRecord<AcademicAssignment>? record;
  final AcademicAssignmentSave onSave;
  final Future<void> Function()? onDelete;
  final VoidCallback onClose;

  @override
  State<AcademicAssignmentEditor> createState() =>
      _AcademicAssignmentEditorState();
}

final class _AcademicAssignmentEditorState
    extends State<AcademicAssignmentEditor> {
  late final TextEditingController _title;
  late final TextEditingController _course;
  late final TextEditingController _dueDate;
  late AcademicAssignmentStatus _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final assignment = widget.record?.value;
    _title = TextEditingController(text: assignment?.title);
    _course = TextEditingController(text: assignment?.course);
    _dueDate = TextEditingController(
      text: assignment == null ? '' : formatUsDate(assignment.dueDate),
    );
    _status = assignment?.status ?? AcademicAssignmentStatus.pending;
  }

  @override
  void dispose() {
    _title.dispose();
    _course.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    LocalDate? current;
    try {
      if (_dueDate.text.trim().isNotEmpty) current = parseUsDate(_dueDate.text);
    } on FormatException {
      // The picker remains available as a recovery path for malformed input.
    }
    final picked = await pickUsDate(context, initialDate: current);
    if (picked != null) _dueDate.text = formatUsDate(picked);
  }

  Future<void> _save() async {
    LocalDate dueDate;
    try {
      dueDate = parseUsDate(_dueDate.text);
      AcademicAssignment(
        id: widget.record?.value.id ?? 'validation-assignment',
        title: _title.text,
        course: _course.text,
        dueDate: dueDate,
        status: _status,
      );
    } on Object catch (error) {
      setState(() => _error = error.toString());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        title: _title.text,
        course: _course.text,
        dueDate: dueDate,
        status: _status,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final delete = widget.onDelete;
    if (delete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: const Text(
          'This removes the Academic Assignment from the Calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await delete();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Column(
        key: const Key('academic-assignment-editor'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              widget.record == null ? 'ADD ASSIGNMENT' : 'ASSIGNMENT DETAILS',
            ),
            trailing: IconButton(
              onPressed: _busy ? null : widget.onClose,
              tooltip: 'Close assignment details',
              icon: const Icon(Icons.close),
            ),
          ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  key: const Key('academic-assignment-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('academic-assignment-title'),
                    controller: _title,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Assignment title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('academic-assignment-course'),
                    controller: _course,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Class or course',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('academic-assignment-due-date'),
                    controller: _dueDate,
                    enabled: !_busy,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Due date (MM-DD-YYYY)',
                      suffixIcon: IconButton(
                        onPressed: _busy ? null : _pickDueDate,
                        tooltip: 'Choose due date',
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                  if (widget.record != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AcademicAssignmentStatus>(
                      key: const Key('academic-assignment-status'),
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: AcademicAssignmentStatus.pending,
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: AcademicAssignmentStatus.completed,
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('save-academic-assignment'),
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      widget.record == null ? 'Add Assignment' : 'Save',
                    ),
                  ),
                  if (widget.onDelete != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('delete-academic-assignment'),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Assignment'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
