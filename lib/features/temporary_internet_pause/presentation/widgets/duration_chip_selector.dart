import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pause_duration_preset.dart';

class DurationChipSelector extends StatelessWidget {
  const DurationChipSelector({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
    this.customDuration,
  });

  final PauseDurationPreset selectedPreset;
  final ValueChanged<PauseDurationPreset> onPresetSelected;
  final Duration? customDuration;

  String _getLabel(PauseDurationPreset preset) {
    if (preset == PauseDurationPreset.custom && customDuration != null) {
      final m = customDuration!.inMinutes;
      if (m >= 60) {
        final h = m ~/ 60;
        final remM = m % 60;
        return remM > 0 ? '${h}h ${remM}m' : '${h}h';
      }
      return '${m}m';
    }
    return preset.label;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PauseDurationPreset.values.map((preset) {
        final isSelected = preset == selectedPreset;
        final label = _getLabel(preset);

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onPresetSelected(preset),
          selectedColor: const Color(0xFFFBBF24),
          backgroundColor: AppColors.cardBackground,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF141D2B) : AppColors.textPrimary,
          ),
          side: BorderSide(
            color: isSelected ? const Color(0xFFFBBF24) : AppColors.cardBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(growable: false),
    );
  }
}
