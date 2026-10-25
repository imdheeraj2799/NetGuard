enum PauseDurationPreset {
  fifteenMinutes(Duration(minutes: 15), '15 min'),
  thirtyMinutes(Duration(minutes: 30), '30 min'),
  oneHour(Duration(hours: 1), '1 hour'),
  twoHours(Duration(hours: 2), '2 hours'),
  custom(Duration.zero, 'Custom');

  const PauseDurationPreset(this.duration, this.label);

  final Duration duration;
  final String label;

  bool get isCustom => this == PauseDurationPreset.custom;
}
