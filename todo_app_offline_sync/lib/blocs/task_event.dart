import 'package:equatable/equatable.dart';

/// Base class for all task events
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all tasks from storage
class LoadTasks extends TaskEvent {
  const LoadTasks();
}

/// Event to add a new task
class AddTask extends TaskEvent {
  final String title;
  final String? description;
  final int? priority;
  final DateTime? dueDate;

  const AddTask({
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
  });

  @override
  List<Object?> get props => [title, description, priority, dueDate];
}

/// Event to update an existing task
class UpdateTask extends TaskEvent {
  final String id;
  final String? title;
  final String? description;
  final int? priority;
  final DateTime? dueDate;
  final bool? completed;

  const UpdateTask({
    required this.id,
    this.title,
    this.description,
    this.priority,
    this.dueDate,
    this.completed,
  });

  @override
  List<Object?> get props => [id, title, description, priority, dueDate, completed];
}

/// Event to delete a task
class DeleteTask extends TaskEvent {
  final String id;

  const DeleteTask(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to toggle task completion status
class ToggleTaskCompletion extends TaskEvent {
  final String id;

  const ToggleTaskCompletion(this.id);

  @override
  List<Object?> get props => [id];
}
