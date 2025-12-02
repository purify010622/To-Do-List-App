import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import 'task_event.dart';
import 'task_state.dart';

/// BLoC for managing task state and operations
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;
  final NotificationService _notificationService;
  StreamSubscription<List<Task>>? _tasksSubscription;

  TaskBloc({
    required TaskRepository repository,
    NotificationService? notificationService,
  })  : _repository = repository,
        _notificationService = notificationService ?? NotificationService(),
        super(const TasksInitial()) {
    // Register event handlers
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<_TasksUpdated>(_onTasksUpdated);
    on<_TasksError>(_onTasksError);
  }

  /// Internal event handler for task updates from stream
  Future<void> _onTasksUpdated(
    _TasksUpdated event,
    Emitter<TaskState> emit,
  ) async {
    emit(TasksLoaded(event.tasks));
  }

  /// Internal event handler for task errors from stream
  Future<void> _onTasksError(
    _TasksError event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskError(event.message));
  }

  /// Handle LoadTasks event
  Future<void> _onLoadTasks(
    LoadTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TasksLoading());

    try {
      // Cancel existing subscription if any
      await _tasksSubscription?.cancel();

      // Subscribe to task stream for reactive updates
      _tasksSubscription = _repository.watchTasks().listen(
        (tasks) {
          // Sort tasks by priority (desc) then dueDate (asc)
          final sortedTasks = _sortTasks(tasks);
          add(_TasksUpdated(sortedTasks));
        },
        onError: (error) {
          add(_TasksError(error.toString()));
        },
      );

      // Also load initial tasks
      final tasks = await _repository.getAllTasks();
      final sortedTasks = _sortTasks(tasks);
      emit(TasksLoaded(sortedTasks));
    } catch (e) {
      emit(TaskError('Failed to load tasks: ${e.toString()}'));
    }
  }

  /// Handle AddTask event
  Future<void> _onAddTask(
    AddTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // Validate title
      if (!Task.isValidTitle(event.title)) {
        emit(const TaskError('Title cannot be empty or whitespace only'));
        return;
      }

      // Validate priority if provided
      final priority = event.priority ?? 3; // Default priority is 3
      if (!Task.isValidPriority(priority)) {
        emit(const TaskError('Priority must be between 1 and 5'));
        return;
      }

      // Validate due date if provided
      if (event.dueDate != null && !Task.isValidDueDate(event.dueDate!)) {
        emit(const TaskError('Due date cannot be in the past'));
        return;
      }

      // Create task with default values
      final task = Task(
        title: event.title,
        description: event.description,
        priority: priority,
        dueDate: event.dueDate,
        completed: false, // Default completed is false
      );

      await _repository.createTask(task);

      // Schedule notification if task has a due date
      if (task.dueDate != null) {
        await _notificationService.scheduleNotification(task);
      }

      // Reload tasks to get updated list
      final tasks = await _repository.getAllTasks();
      final sortedTasks = _sortTasks(tasks);
      emit(TasksLoaded(sortedTasks));
    } catch (e) {
      emit(TaskError('Failed to add task: ${e.toString()}'));
    }
  }

  /// Handle UpdateTask event
  Future<void> _onUpdateTask(
    UpdateTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // Get existing task
      final existingTask = await _repository.getTaskById(event.id);
      if (existingTask == null) {
        emit(TaskError('Task not found: ${event.id}'));
        return;
      }

      // Validate title if provided
      if (event.title != null && !Task.isValidTitle(event.title!)) {
        emit(const TaskError('Title cannot be empty or whitespace only'));
        return;
      }

      // Validate priority if provided
      if (event.priority != null && !Task.isValidPriority(event.priority!)) {
        emit(const TaskError('Priority must be between 1 and 5'));
        return;
      }

      // Validate due date if provided
      if (event.dueDate != null && !Task.isValidDueDate(event.dueDate!)) {
        emit(const TaskError('Due date cannot be in the past'));
        return;
      }

      // Update task with new values, preserving ID
      final updatedTask = existingTask.copyWith(
        title: event.title,
        description: event.description,
        priority: event.priority,
        dueDate: event.dueDate,
        completed: event.completed,
      );

      await _repository.updateTask(updatedTask);

      // Cancel existing notification
      await _notificationService.cancelNotification(updatedTask.id);

      // Schedule new notification if task has a due date and is not completed
      if (updatedTask.dueDate != null && !updatedTask.completed) {
        await _notificationService.scheduleNotification(updatedTask);
      }

      // Reload tasks to get updated list
      final tasks = await _repository.getAllTasks();
      final sortedTasks = _sortTasks(tasks);
      emit(TasksLoaded(sortedTasks));
    } catch (e) {
      emit(TaskError('Failed to update task: ${e.toString()}'));
    }
  }

  /// Handle DeleteTask event
  Future<void> _onDeleteTask(
    DeleteTask event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // Note: Confirmation should be handled at the UI level
      // This handler assumes confirmation has already been obtained
      
      // Cancel notification for the task
      await _notificationService.cancelNotification(event.id);
      
      await _repository.deleteTask(event.id);

      // Reload tasks to get updated list
      final tasks = await _repository.getAllTasks();
      final sortedTasks = _sortTasks(tasks);
      emit(TasksLoaded(sortedTasks));
    } catch (e) {
      emit(TaskError('Failed to delete task: ${e.toString()}'));
    }
  }

  /// Handle ToggleTaskCompletion event
  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletion event,
    Emitter<TaskState> emit,
  ) async {
    try {
      // Get existing task
      final existingTask = await _repository.getTaskById(event.id);
      if (existingTask == null) {
        emit(TaskError('Task not found: ${event.id}'));
        return;
      }

      // Toggle completion status
      final updatedTask = existingTask.copyWith(
        completed: !existingTask.completed,
      );

      await _repository.updateTask(updatedTask);

      // Cancel notification if task is now completed
      if (updatedTask.completed) {
        await _notificationService.cancelNotification(updatedTask.id);
      } else if (updatedTask.dueDate != null) {
        // Reschedule notification if task is uncompleted and has a due date
        await _notificationService.scheduleNotification(updatedTask);
      }

      // Reload tasks to get updated list
      final tasks = await _repository.getAllTasks();
      final sortedTasks = _sortTasks(tasks);
      emit(TasksLoaded(sortedTasks));
    } catch (e) {
      emit(TaskError('Failed to toggle task completion: ${e.toString()}'));
    }
  }



  /// Sort tasks by priority (descending) then by dueDate (ascending)
  List<Task> _sortTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      // First sort by priority (highest first)
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // Then sort by due date (earliest first)
      // Tasks without due dates go to the end
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sortedTasks;
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}

/// Internal event for task updates from stream
class _TasksUpdated extends TaskEvent {
  final List<Task> tasks;

  const _TasksUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

/// Internal event for task errors from stream
class _TasksError extends TaskEvent {
  final String message;

  const _TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
