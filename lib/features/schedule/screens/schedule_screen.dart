import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/gemini_service.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/models/task_model.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _preferencesController = TextEditingController();
  double _availableHours = 6.0;
  final List<String> _selectedTaskIds = [];
  bool _isGenerating = false;
  bool _isPlannerView = false; // Toggle between history list and planner editor

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _generateSchedule(List<TaskModel> pendingTasks) async {
    if (!GeminiService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API is not configured. Add your key in Settings.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final chosenTasks = pendingTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
    if (chosenTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one task to schedule.')),
      );
      return;
    }

    // Privacy Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm AI Plan'),
        content: Text(
          'This will send details (titles and deadlines) of ${chosenTasks.length} task(s) to Gemini API to create your schedule. Do you proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGenerating = true);

    try {
      final tasksMapList = chosenTasks.map((t) => {
        'title': t.title,
        'description': t.description,
        'priority': t.priority.name,
        'deadline': t.deadline != null ? DateFormat('MMM d, h:mm a').format(t.deadline!) : 'None',
      }).toList();

      final result = await GeminiService().generateSchedule(
        tasks: tasksMapList,
        availableHours: _availableHours,
        preferences: _preferencesController.text.trim(),
      );

      await ref.read(scheduleProvider.notifier).addSchedule(
            generatedText: result,
            availableHours: _availableHours,
            preferences: _preferencesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Schedule generated successfully!'), backgroundColor: AppColors.success),
        );
        setState(() {
          _isPlannerView = false;
          _selectedTaskIds.clear();
          _preferencesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Plan Generation Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedulesState = ref.watch(scheduleProvider);
    final tasksState = ref.watch(taskListProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Planner',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isPlannerView ? 'Design your routine schedule' : 'Your saved schedules & routines',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isPlannerView = !_isPlannerView);
                    },
                    icon: Icon(_isPlannerView ? Icons.history_rounded : Icons.auto_awesome_rounded),
                    label: Text(_isPlannerView ? 'History' : 'New Plan'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // View Selector
              Expanded(
                child: _isPlannerView
                    ? tasksState.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                        data: (tasks) {
                          final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
                          
                          if (pendingTasks.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pending tasks!',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('You need pending tasks to draft an AI schedule.'),
                                ],
                              ),
                            );
                          }

                          return _buildPlannerForm(pendingTasks);
                        },
                      )
                    : schedulesState.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                        data: (schedules) {
                          if (schedules.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No schedules generated yet',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Tap "New Plan" at the top right to start planning.',
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: schedules.length,
                            itemBuilder: (context, idx) {
                              final schedule = schedules[idx];
                              return _buildScheduleHistoryCard(schedule);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerForm(List<TaskModel> pendingTasks) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '1. Available Planning Time',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _availableHours,
                        min: 1,
                        max: 16,
                        divisions: 15,
                        label: '${_availableHours.toInt()} Hours',
                        onChanged: (val) => setState(() => _availableHours = val),
                      ),
                    ),
                    Text(
                      '${_availableHours.toInt()} hrs',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  '2. Routine Preferences',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _preferencesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Include lunch break at 1 PM, focus on study, etc.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Task Selector
          Text(
            '3. Select Tasks to Include',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingTasks.length,
            itemBuilder: (context, idx) {
              final task = pendingTasks[idx];
              final isSelected = _selectedTaskIds.contains(task.id);
              return CheckboxListTile(
                title: Text(task.title),
                subtitle: Text('Priority: ${task.priority.name}'),
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedTaskIds.add(task.id);
                    } else {
                      _selectedTaskIds.remove(task.id);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isGenerating ? null : () => _generateSchedule(pendingTasks),
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bolt_rounded),
            label: Text(_isGenerating ? 'AI Planning in Progress...' : 'Generate AI Schedule Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHistoryCard(ScheduleModel schedule) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(schedule.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          dateStr,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Target: ${schedule.availableHours.toInt()} hrs | Prefs: ${schedule.preferences.isEmpty ? "None" : schedule.preferences}',
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () {
            ref.read(scheduleProvider.notifier).deleteSchedule(schedule.id);
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: schedule.generatedText,
                selectable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
