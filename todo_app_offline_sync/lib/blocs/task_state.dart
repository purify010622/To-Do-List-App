import 'package:equatable/equatable.dart';
import '../models/task.dart';

/// Base class for all task states
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any tasks are loaded
class TasksInitial extends TaskState {
  const TasksInitial();
}

/// State when tasks are being loaded
class TasksLoading extends TaskState {
  const TasksLoading();
}

/// State when tasks have been successfully loaded
class TasksLoaded extends TaskState {
  final List<Task> tasks;

  const TasksLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

/// State when an error occurs
class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
