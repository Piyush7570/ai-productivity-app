import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/schedule_model.dart';
import '../repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

class ScheduleNotifier extends StateNotifier<AsyncValue<List<ScheduleModel>>> {
  final ScheduleRepository _repository;
  final String _userId;

  ScheduleNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    try {
      final list = await _repository.getSchedules(_userId);
      // Sort: newest schedule first
      list.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSchedule({
    required String generatedText,
    required double availableHours,
    required String preferences,
  }) async {
    final list = state.value ?? [];
    final newSchedule = ScheduleModel(
      id: const Uuid().v4(),
      userId: _userId,
      date: DateTime.now(),
      generatedText: generatedText,
      availableHours: availableHours,
      preferences: preferences,
    );

    state = AsyncValue.data([newSchedule, ...list]);

    try {
      await _repository.saveSchedule(newSchedule);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSchedule(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((s) => s.id != id).toList());

    try {
      await _repository.deleteSchedule(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<ScheduleModel>>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;
  final userId = user?.uid ?? 'guest';
  return ScheduleNotifier(repository, userId);
});
