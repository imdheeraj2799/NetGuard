import 'package:flutter/foundation.dart';

class ScheduleConflictResult {
  const ScheduleConflictResult({
    required this.isValid,
    this.conflictingPackages = const <String, String>{},
    this.errorMessage,
  });

  final bool isValid;
  final Map<String, String> conflictingPackages; // packageName -> owning schedule name
  final String? errorMessage;

  bool get hasConflicts => conflictingPackages.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleConflictResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          mapEquals(conflictingPackages, other.conflictingPackages) &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        isValid,
        Object.hashAll(conflictingPackages.entries),
        errorMessage,
      );
}
