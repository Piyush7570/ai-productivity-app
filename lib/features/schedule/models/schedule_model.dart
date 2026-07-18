class ScheduleModel {
  final String id;
  final String userId;
  final DateTime date;
  final String generatedText;
  final double availableHours;
  final String preferences;

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.generatedText,
    required this.availableHours,
    required this.preferences,
  });

  factory ScheduleModel.fromMap(Map<dynamic, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      generatedText: map['generatedText'] ?? '',
      availableHours: (map['availableHours'] ?? 0.0) as double,
      preferences: map['preferences'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'generatedText': generatedText,
      'availableHours': availableHours,
      'preferences': preferences,
    };
  }
}
