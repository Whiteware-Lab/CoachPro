import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter/services.dart';

class AthleteTimerButton extends StatelessWidget {
  const AthleteTimerButton({
    required this.athlete,
    required this.splits,
    required this.onTap,
    required this.onLongPress,
    required this.enabled,
    super.key,
  });

  final Athlete athlete;
  final List<Split> splits;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final athleteSplits = splits
        .where((split) => split.athleteId == athlete.id)
        .toList()
      ..sort((a, b) => a.lapNumber.compareTo(b.lapNumber));
    final lapCount = athleteSplits.length;
    final lastSplit = athleteSplits.isEmpty ? null : athleteSplits.last;

    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        onLongPress: enabled
            ? () {
                HapticFeedback.heavyImpact();
                onLongPress();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                athlete.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (lapCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'G$lapCount: ${formatElapsedMs(lastSplit!.elapsedMs)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FinishedAthleteTile extends StatelessWidget {
  const FinishedAthleteTile({
    required this.athlete,
    required this.splits,
    super.key,
  });

  final Athlete athlete;
  final List<Split> splits;

  @override
  Widget build(BuildContext context) {
    final athleteSplits = splits
        .where((split) => split.athleteId == athlete.id)
        .toList()
      ..sort((a, b) => a.lapNumber.compareTo(b.lapNumber));
    final totalMs =
        athleteSplits.isEmpty ? 0 : athleteSplits.last.elapsedMs;

    return Card(
      color: AppColors.surfaceVariant,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.success),
        title: Text(athlete.name),
        subtitle: Text('${athleteSplits.length} giri'),
        trailing: Text(
          formatElapsedMs(totalMs),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
