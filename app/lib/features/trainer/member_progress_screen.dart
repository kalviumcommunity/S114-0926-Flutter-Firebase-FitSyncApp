import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../models/progress_log.dart';
import '../../services/firestore_service.dart';

class MemberProgressScreen extends ConsumerWidget {
  final AppUser member;

  const MemberProgressScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(memberProgressLogsProvider(member.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(member.displayName),
      ),
      body: progressAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('No progress logs yet',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            );
          }

          // Group by date
          final grouped = <DateTime, List<ProgressLog>>{};
          for (final log in logs) {
            final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
            grouped.putIfAbsent(dateKey, () => []).add(log);
          }
          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayLogs = grouped[date]!;
              return _DayLogsCard(date: date, logs: dayLogs);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DayLogsCard extends StatelessWidget {
  final DateTime date;
  final List<ProgressLog> logs;

  const _DayLogsCard({required this.date, required this.logs});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);
    
    if (logDate == today) return 'Today';
    if (logDate == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...logs.map((log) => _LogTile(log: log)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ProgressLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final iconData = switch (log.type) {
      LogType.workout => Icons.fitness_center,
      LogType.measurement => Icons.straighten,
      LogType.photo => Icons.photo_camera,
      LogType.note => Icons.note,
    };
    
    final iconColor = switch (log.type) {
      LogType.workout => Colors.green,
      LogType.measurement => Colors.blue,
      LogType.photo => Colors.purple,
      LogType.note => Colors.orange,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(_getLogTitle(log)),
      subtitle: Text(_getLogSubtitle(log)),
      trailing: log.difficultyRating != null
          ? Chip(
              label: Text('${log.difficultyRating}/10',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: _getDifficultyColor(log.difficultyRating!).withOpacity(0.2),
            )
          : null,
    );
  }

  String _getLogTitle(ProgressLog log) {
    return switch (log.type) {
      LogType.workout => log.workoutName ?? 'Workout',
      LogType.measurement => 'Body Measurements',
      LogType.photo => 'Progress Photos',
      LogType.note => log.notes ?? 'Note',
    };
  }

  String _getLogSubtitle(ProgressLog log) {
    final parts = <String>[];
    
    if (log.type == LogType.workout) {
      if (log.durationMinutes != null) parts.add('${log.durationMinutes} min');
      if (log.caloriesBurned != null) parts.add('${log.caloriesBurned!.toInt()} cal');
      if (log.completedExercises != null) parts.add('${log.completedExercises!.length} exercises');
    } else if (log.type == LogType.measurement) {
      if (log.weightKg != null) parts.add('Weight: ${log.weightKg} kg');
      if (log.bodyFatPercentage != null) parts.add('Body Fat: ${log.bodyFatPercentage}%');
    } else if (log.type == LogType.photo) {
      parts.add('${log.photoUrls?.length ?? 0} photo(s)');
    }
    
    if (log.notes != null && log.notes!.isNotEmpty) {
      parts.add(log.notes!);
    }
    
    return parts.join(' · ');
  }

  Color _getDifficultyColor(int rating) {
    if (rating <= 3) return Colors.green;
    if (rating <= 6) return Colors.orange;
    return Colors.red;
  }
}