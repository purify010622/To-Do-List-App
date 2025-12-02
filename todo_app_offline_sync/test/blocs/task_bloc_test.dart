import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/blocs/task_bloc_exports.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/services/notification_service.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';

/// Mock notification service for testing
class MockNotificationService implements NotificationService {
  final Set<String> _scheduledNotifications = {};
  final Set<String> _cancelledNotifications = {};

  @override
  Function(String taskId)? onNotificationTap;

  @override
  Future<void> initialize() async {
    // No-op for testing
  }

  @override
  Future<void> scheduleNotification(Task task) async {
    _scheduledNotifications.add(task.id);
    _cancelledNotifications.remove(task.id);
  }

  @override
  Future<void> cancelNotification(String taskId) async {
    _cancelledNotifications.add(taskId);
    _scheduledNotifications.remove(taskId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
  }

  @override
  Future<bool> isNotificationScheduled(String taskId) async {
    return _scheduledNotifications.contains(taskId) &&
        !_cancelledNotifications.contains(taskId);
  }

  bool wasNotificationCancelled(String taskId) {
    return _cancelledNotifications.contains(taskId);
  }

  void reset() {
    _scheduledNotifications.clear();
    _cancelledNotifications.clear();
  }
}

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskBloc Property Tests', () {

    // Feature: todo-app-offline-sync, Property: Default completion status and priority
    // Validates: Requirements 1.5, 2.4
    test('Property: Tasks created without explicit values get default completion (false) and priority (3)', () async {
      final dbHelper = DatabaseHelper.test('test_default_values_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final taskBloc = TaskBloc(repository: repository);
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Generate random task title
          final title = faker.lorem.sentence();

          // Add task without specifying priority or completion
          taskBloc.add(AddTask(
            title: title,
            description: faker.lorem.sentence(),
          ));

          // Wait for the task to be added
          await Future.delayed(const Duration(milliseconds: 50));

          // Get all tasks
          final tasks = await repository.getAllTasks();

          // Find the task we just added
          final addedTask = tasks.firstWhere(
            (task) => task.title == title,
            orElse: () => throw Exception('Task not found'),
          );

          // Verify default values
          expect(addedTask.completed, false,
              reason: 'Task should have default completed status of false');
          expect(addedTask.priority, 3,
              reason: 'Task should have default priority of 3');
        }
      } finally {
        await taskBloc.close();
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 6: Task sorting consistency
    // Validates: Requirements 3.4
    test('Property 6: Tasks are always sorted by priority (desc) then dueDate (asc)', () async {
      final dbHelper = DatabaseHelper.test('test_sorting_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Create multiple tasks with random priorities and due dates
          final numTasks = faker.randomGenerator.integer(10, min: 3);
          
          for (int j = 0; j < numTasks; j++) {
            final priority = faker.randomGenerator.integer(5, min: 1);
            final daysInFuture = faker.randomGenerator.integer(30, min: 1);
            final dueDate = DateTime.now().add(Duration(days: daysInFuture));
            
            await repository.createTask(Task(
              title: faker.lorem.sentence(),
              description: faker.lorem.sentence(),
              priority: priority,
              dueDate: faker.randomGenerator.boolean() ? dueDate : null,
            ));
          }

          // Get all tasks
          final tasks = await repository.getAllTasks();

          // Verify sorting: priority descending, then dueDate ascending
          for (int k = 0; k < tasks.length - 1; k++) {
            final current = tasks[k];
            final next = tasks[k + 1];

            // Check priority ordering (higher priority comes first)
            if (current.priority != next.priority) {
              expect(current.priority, greaterThan(next.priority),
                  reason: 'Tasks should be sorted by priority descending');
            } else {
              // If priorities are equal, check due date ordering
              if (current.dueDate != null && next.dueDate != null) {
                expect(current.dueDate!.isBefore(next.dueDate!) || 
                       current.dueDate!.isAtSameMomentAs(next.dueDate!), 
                       true,
                       reason: 'Tasks with same priority should be sorted by due date ascending');
              } else if (current.dueDate != null && next.dueDate == null) {
                // Tasks with due dates should come before tasks without
                // This is valid
              }
            }
          }

          // Clean up for next iteration
          for (final task in tasks) {
            await repository.deleteTask(task.id);
          }
          
          // Wait for async operations to complete
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } finally {
        // Wait before disposing to ensure all async operations complete
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 7: Task update preserves identity
    // Validates: Requirements 4.2, 4.3, 4.4
    test('Property 7: Updating a task preserves its ID and only modifies specified fields', () async {
      final dbHelper = DatabaseHelper.test('test_update_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final taskBloc = TaskBloc(repository: repository);
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Create a task
          final originalTitle = faker.lorem.sentence();
          final originalDescription = faker.lorem.sentence();
          final originalPriority = faker.randomGenerator.integer(5, min: 1);
          final originalDueDate = DateTime.now().add(Duration(days: faker.randomGenerator.integer(30, min: 1)));
          
          taskBloc.add(AddTask(
            title: originalTitle,
            description: originalDescription,
            priority: originalPriority,
            dueDate: originalDueDate,
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the created task
          final tasks = await repository.getAllTasks();
          final originalTask = tasks.firstWhere((task) => task.title == originalTitle);
          final originalId = originalTask.id;
          
          // Update only some fields
          final newTitle = faker.lorem.sentence();
          taskBloc.add(UpdateTask(
            id: originalId,
            title: newTitle,
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the updated task
          final updatedTask = await repository.getTaskById(originalId);
          
          // Verify ID is preserved
          expect(updatedTask?.id, originalId,
              reason: 'Task ID should be preserved after update');
          
          // Verify updated field changed
          expect(updatedTask?.title, newTitle,
              reason: 'Updated field should have new value');
          
          // Verify non-updated fields remain the same
          expect(updatedTask?.description, originalDescription,
              reason: 'Non-updated fields should remain unchanged');
          expect(updatedTask?.priority, originalPriority,
              reason: 'Non-updated fields should remain unchanged');
          
          // Clean up
          await repository.deleteTask(originalId);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } finally {
        await taskBloc.close();
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 8: Completion toggle idempotence
    // Validates: Requirements 5.1, 5.4
    test('Property 8: Toggling completion twice returns task to original state', () async {
      final dbHelper = DatabaseHelper.test('test_toggle_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final taskBloc = TaskBloc(repository: repository);
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Create a task
          taskBloc.add(AddTask(
            title: faker.lorem.sentence(),
            description: faker.lorem.sentence(),
            priority: faker.randomGenerator.integer(5, min: 1),
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the created task
          final tasks = await repository.getAllTasks();
          final task = tasks.last;
          final taskId = task.id;
          final originalCompleted = task.completed;
          
          // Toggle completion once
          taskBloc.add(ToggleTaskCompletion(taskId));
          await Future.delayed(const Duration(milliseconds: 50));
          
          final afterFirstToggle = await repository.getTaskById(taskId);
          expect(afterFirstToggle?.completed, !originalCompleted,
              reason: 'First toggle should change completion status');
          
          // Toggle completion again
          taskBloc.add(ToggleTaskCompletion(taskId));
          await Future.delayed(const Duration(milliseconds: 50));
          
          final afterSecondToggle = await repository.getTaskById(taskId);
          expect(afterSecondToggle?.completed, originalCompleted,
              reason: 'Second toggle should return to original completion status');
          
          // Clean up
          await repository.deleteTask(taskId);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } finally {
        await taskBloc.close();
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 9: Deletion removes task completely
    // Validates: Requirements 6.2
    test('Property 9: After deletion, task cannot be retrieved by ID', () async {
      final dbHelper = DatabaseHelper.test('test_deletion_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final taskBloc = TaskBloc(repository: repository);
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Create a task
          taskBloc.add(AddTask(
            title: faker.lorem.sentence(),
            description: faker.lorem.sentence(),
            priority: faker.randomGenerator.integer(5, min: 1),
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the created task
          final tasks = await repository.getAllTasks();
          final task = tasks.last;
          final taskId = task.id;
          
          // Verify task exists
          final taskBeforeDeletion = await repository.getTaskById(taskId);
          expect(taskBeforeDeletion, isNotNull,
              reason: 'Task should exist before deletion');
          
          // Delete the task
          taskBloc.add(DeleteTask(taskId));
          await Future.delayed(const Duration(milliseconds: 150)); // Increased delay for async operation
          
          // Verify task no longer exists
          final taskAfterDeletion = await repository.getTaskById(taskId);
          expect(taskAfterDeletion, isNull,
              reason: 'Task should not exist after deletion');
          
          // Verify task is not in the list
          final allTasks = await repository.getAllTasks();
          final deletedTaskInList = allTasks.any((t) => t.id == taskId);
          expect(deletedTaskInList, false,
              reason: 'Deleted task should not appear in task list');
        }
      } finally {
        await taskBloc.close();
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 10: Notification cancellation on completion
    // Validates: Requirements 5.5, 7.4
    test('Property 10: Marking a task as completed cancels its scheduled notification', () async {
      final dbHelper = DatabaseHelper.test('test_notif_complete_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final mockNotificationService = MockNotificationService();
      final taskBloc = TaskBloc(
        repository: repository,
        notificationService: mockNotificationService,
      );
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          mockNotificationService.reset();
          
          // Create a task with a due date (within 24 hours to trigger notification)
          final dueDate = DateTime.now().add(const Duration(hours: 2));
          
          taskBloc.add(AddTask(
            title: faker.lorem.sentence(),
            description: faker.lorem.sentence(),
            priority: faker.randomGenerator.integer(5, min: 1),
            dueDate: dueDate,
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the created task
          final tasks = await repository.getAllTasks();
          final task = tasks.last;
          final taskId = task.id;
          
          // Verify notification was scheduled
          final wasScheduled = await mockNotificationService.isNotificationScheduled(taskId);
          expect(wasScheduled, true,
              reason: 'Notification should be scheduled for task with due date');
          
          // Toggle completion to mark as completed
          taskBloc.add(ToggleTaskCompletion(taskId));
          await Future.delayed(const Duration(milliseconds: 150)); // Increased delay for async operation
          
          // Verify notification was cancelled
          final wasCancelled = mockNotificationService.wasNotificationCancelled(taskId);
          expect(wasCancelled, true,
              reason: 'Notification should be cancelled when task is marked completed');
          
          final isStillScheduled = await mockNotificationService.isNotificationScheduled(taskId);
          expect(isStillScheduled, false,
              reason: 'Notification should not be scheduled after task completion');
          
          // Clean up
          await repository.deleteTask(taskId);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } finally {
        await taskBloc.close();
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 11: Notification cancellation on deletion
    // Validates: Requirements 6.4, 7.4
    test('Property 11: Deleting a task cancels its scheduled notification', () async {
      final dbHelper = DatabaseHelper.test('test_notif_delete_${DateTime.now().millisecondsSinceEpoch}.db');
      final repository = LocalStorageService(dbHelper: dbHelper);
      final mockNotificationService = MockNotificationService();
      final taskBloc = TaskBloc(
        repository: repository,
        notificationService: mockNotificationService,
      );
      
      try {
        final faker = Faker();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          mockNotificationService.reset();
          
          // Create a task with a due date (within 24 hours to trigger notification)
          final dueDate = DateTime.now().add(const Duration(hours: 2));
          
          taskBloc.add(AddTask(
            title: faker.lorem.sentence(),
            description: faker.lorem.sentence(),
            priority: faker.randomGenerator.integer(5, min: 1),
            dueDate: dueDate,
          ));
          
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Get the created task
          final tasks = await repository.getAllTasks();
          final task = tasks.last;
          final taskId = task.id;
          
          // Verify notification was scheduled
          final wasScheduled = await mockNotificationService.isNotificationScheduled(taskId);
          expect(wasScheduled, true,
              reason: 'Notification should be scheduled for task with due date');
          
          // Delete the task
          taskBloc.add(DeleteTask(taskId));
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Verify notification was cancelled
          final wasCancelled = mockNotificationService.wasNotificationCancelled(taskId);
          expect(wasCancelled, true,
              reason: 'Notification should be cancelled when task is deleted');
          
          final isStillScheduled = await mockNotificationService.isNotificationScheduled(taskId);
          expect(isStillScheduled, false,
              reason: 'Notification should not be scheduled after task deletion');
        }
      } finally {
        await taskBloc.close();
        await Future.delayed(const Duration(milliseconds: 100));
        repository.dispose();
        await dbHelper.close();
      }
    });
  });
}
