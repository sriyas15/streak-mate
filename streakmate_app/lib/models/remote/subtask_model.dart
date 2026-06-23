/// subtask_model.dart
/// Mirrors backend subtaskSchema exactly — these are the REAL persisted
/// subtask docs returned by onboardingService.selectHabits /
/// configureSubtasks, as opposed to the static SubtaskTemplate mirrors.
class SubtaskModel {
  final String id;
  final String habitId;
  final String userId;
  final String name;
  final String? icon;
  final String inputType; // checkbox | quantity | timer
  final String? unit;
  final num? targetValue;
  final bool isRequired;
  final int displayOrder;
  final bool isActive;

  const SubtaskModel({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.name,
    this.icon,
    required this.inputType,
    this.unit,
    this.targetValue,
    required this.isRequired,
    required this.displayOrder,
    required this.isActive,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['_id'] as String,
      habitId: json['habitId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      inputType: json['inputType'] as String? ?? 'checkbox',
      unit: json['unit'] as String?,
      targetValue: json['targetValue'] as num?,
      isRequired: json['isRequired'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  SubtaskModel copyWith({bool? isActive}) {
    return SubtaskModel(
      id: id,
      habitId: habitId,
      userId: userId,
      name: name,
      icon: icon,
      inputType: inputType,
      unit: unit,
      targetValue: targetValue,
      isRequired: isRequired,
      displayOrder: displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
