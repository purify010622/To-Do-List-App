import 'package:uuid/uuid.dart';

/// Task model representing a to-do item with all required fields
class Task {
  final String id;
  final String title;
  final String? description;
  final int priority; // 1-5, default 3
  final DateTime? dueDate;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    String? id,
    required this.title,
    this.description,
    int? priority,
    this.dueDate,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        priority = priority ?? 3,
        completed = completed ?? false,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Validate on construction
    if (!isValidTitle(title)) {
      throw ArgumentError('Title cannot be empty or whitespace only');
    }
    if (!isValidPriority(this.priority)) {
      throw ArgumentError('Priority must be between 1 and 5');
    }
    if (dueDate != null && !isValidDueDate(dueDate!)) {
      throw ArgumentError('Due date cannot be in the past');
    }
  }

  /// Validates that a title is non-empty and not just whitespace
  static bool isValidTitle(String title) {
    return title.trim().isNotEmpty;
  }

  /// Validates that priority is within the valid range (1-5)
  static bool isValidPriority(int priority) {
    return priority >= 1 && priority <= 5;
  }

  /// Validates that a due date is not in the past
  static bool isValidDueDate(DateTime dueDate) {
    return dueDate.isAfter(DateTime.now());
  }

  /// Creates a copy of this task with the specified fields replaced
  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? priority,
    DateTime? dueDate,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts this task to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a task from a JSON map
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as int,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.dueDate == dueDate &&
        other.completed == completed &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      priority,
      dueDate,
      completed,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, completed: $completed)';
  }
}
