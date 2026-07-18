import '../../../core/services/db_service.dart';
import '../models/schedule_model.dart';

class ScheduleRepository {
  Future<List<ScheduleModel>> getSchedules(String userId) async {
    final box = DatabaseService.schedulesBox;
    return box.values
        .map((map) => ScheduleModel.fromMap(map))
        .where((schedule) => schedule.userId == userId)
        .toList();
  }

  Future<void> saveSchedule(ScheduleModel schedule) async {
    await DatabaseService.schedulesBox.put(schedule.id, schedule.toMap());
  }

  Future<void> deleteSchedule(String id) async {
    await DatabaseService.schedulesBox.delete(id);
  }
}
