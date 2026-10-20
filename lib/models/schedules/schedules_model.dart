import 'dart:convert';

/// Top-level API response: { "message": "...", "data": [ ... ] }
class ScheduleResponse {
  final String message;
  final List<Schedule> data;

  const ScheduleResponse({required this.message, required this.data});

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleResponse(
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ScheduleResponse.fromRawJson(String source) =>
      ScheduleResponse.fromJson(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };

  String toRawJson() => json.encode(toJson());
}

/// A single schedule item.
class Schedule {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String priority; // e.g. "high"
  final String status; // e.g. "scheduled"
  final String categoryName; // e.g. "Study" (comes from the new view)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Schedule({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.priority,
    required this.status,
    required this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      title: json['title'] as String? ?? '',
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'title': title,
    'start_at': startAt.toUtc().toIso8601String(),
    'end_at': endAt.toUtc().toIso8601String(),
    'priority': priority,
    'status': status,
    'category_name': categoryName,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  /// Length of the schedule.
  Duration get duration => endAt.difference(startAt);

  /// Start / end converted to the device's local time zone.
  DateTime get localStartAt => startAt.toLocal();
  DateTime get localEndAt => endAt.toLocal();

  @override
  String toString() =>
      'Schedule(id: $id, title: $title, startAt: $startAt, endAt: $endAt, '
      'priority: $priority, status: $status, categoryName: $categoryName)';
}
