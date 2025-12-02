import '../models/task.dart';

/// Abstract repository interface for task operations
abstract class TaskRepository {
  /// Get all tasks from storage
  Future<List<Task>> getAllTasks();

  /// Get a specific task by ID
  Future<Task?> getTaskById(String id);

  /// Create a new task
  Future<void> createTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task by ID
  Future<void> deleteTask(String id);

  /// Watch tasks for reactive updates
  Stream<List<Task>> watchTasks();
}
