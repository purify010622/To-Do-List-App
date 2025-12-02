import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:faker/faker.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';

/// Feature: todo-app-offline-sync, Property 15: Offline operation completeness
/// Validates: Requirements 11.1, 11.2, 11.3
///
/// Property: For any task operation (create, update, delete, toggle completion)
/// performed while offline, the operation should complete successfully using
/// LocalStorage without requiring network connectivity.
void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Property 15: Offline operation completeness', () {
    late LocalStorageService storage;
    late DatabaseHelper dbHelper;
    final faker = Faker();

    setUp(() {
      // Create a unique test database for each test
      final dbName = 'test_offline_${DateTime.now().millisecondsSinceEpoch}.db';
      dbHelper = DatabaseHelper.test(dbName);
      storage = LocalStorageService(dbHelper: dbHelper);
    });

    tearDown(() async {
      storage.dispose();
      await Future.delayed(const Duration(milliseconds: 10));
      await dbHelper.close();
    });

    test('Property: Create operation completes offline for any valid task',
        () async {
      // Run 100 iterations with random tasks
      for (int i = 0; i < 100; i++) {
        // Generate random valid task
        final task = Task(
          title: faker.lorem.sentence(),
          description: faker.randomGenerator.boolean()
              ? faker.lorem.sentences(3).join(' ')
              : null,
          priority: faker.randomGenerator.integer(5, min: 1),
          dueDate: faker.randomGenerator.boolean()
              ? DateTime.now().add(Duration(
                  days: faker.randomGenerator.integer(365, min: 1)))
              : null,
          completed: faker.randomGenerator.boolean(),
        );

        // Perform create operation (simulating offline)
        await storage.createTask(task);

        // Verify operation completed successfully
        final retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull,
            reason: 'Task should be created offline (iteration $i)');
        expect(retrieved!.id, equals(task.id),
            reason: 'Task ID should match (iteration $i)');
        expect(retrieved.title, equals(task.title),
            reason: 'Task title should match (iteration $i)');
      }
    });

    test('Property: Update operation completes offline for any task', () async {
      // Run 100 iterations with random updates
      for (int i = 0; i < 100; i++) {
        // Create initial task
        final originalTask = Task(
          title: faker.lorem.sentence(),
          priority: faker.randomGenerator.integer(5, min: 1),
        );
        await storage.createTask(originalTask);

        // Generate random updates
        final updatedTask = originalTask.copyWith(
          title: faker.randomGenerator.boolean()
              ? faker.lorem.sentence()
              : originalTask.title,
          description: faker.randomGenerator.boolean()
              ? faker.lorem.sentences(2).join(' ')
              : originalTask.description,
          priority: faker.randomGenerator.boolean()
              ? faker.randomGenerator.integer(5, min: 1)
              : originalTask.priority,
          dueDate: faker.randomGenerator.boolean()
              ? DateTime.now().add(Duration(
                  days: faker.randomGenerator.integer(365, min: 1)))
              : originalTask.dueDate,
          completed: faker.randomGenerator.boolean(),
        );

        // Perform update operation (simulating offline)
        await storage.updateTask(updatedTask);

        // Verify operation completed successfully
        final retrieved = await storage.getTaskById(originalTask.id);
        expect(retrieved, isNotNull,
            reason: 'Task should exist after update (iteration $i)');
        expect(retrieved!.id, equals(originalTask.id),
            reason: 'Task ID should be preserved (iteration $i)');
        expect(retrieved.title, equals(updatedTask.title),
            reason: 'Task should be updated (iteration $i)');
      }
    });

    test('Property: Delete operation completes offline for any task', () async {
      // Run 100 iterations with random deletions
      for (int i = 0; i < 100; i++) {
        // Create task to delete
        final task = Task(
          title: faker.lorem.sentence(),
          priority: faker.randomGenerator.integer(5, min: 1),
          completed: faker.randomGenerator.boolean(),
        );
        await storage.createTask(task);

        // Verify task exists
        var retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull,
            reason: 'Task should exist before deletion (iteration $i)');

        // Perform delete operation (simulating offline)
        await storage.deleteTask(task.id);

        // Verify operation completed successfully
        retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNull,
            reason: 'Task should be deleted offline (iteration $i)');
      }
    });

    test(
        'Property: Toggle completion operation completes offline for any task',
        () async {
      // Run 100 iterations with random toggles
      for (int i = 0; i < 100; i++) {
        // Create task with random initial completion status
        final initialCompleted = faker.randomGenerator.boolean();
        final task = Task(
          title: faker.lorem.sentence(),
          priority: faker.randomGenerator.integer(5, min: 1),
          completed: initialCompleted,
        );
        await storage.createTask(task);

        // Toggle completion (simulating offline)
        final toggledTask = task.copyWith(completed: !initialCompleted);
        await storage.updateTask(toggledTask);

        // Verify operation completed successfully
        final retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull,
            reason: 'Task should exist after toggle (iteration $i)');
        expect(retrieved!.completed, equals(!initialCompleted),
            reason: 'Completion status should be toggled (iteration $i)');

        // Toggle back
        final toggledBack = toggledTask.copyWith(completed: initialCompleted);
        await storage.updateTask(toggledBack);

        // Verify second toggle
        final retrievedAgain = await storage.getTaskById(task.id);
        expect(retrievedAgain, isNotNull,
            reason: 'Task should exist after second toggle (iteration $i)');
        expect(retrievedAgain!.completed, equals(initialCompleted),
            reason:
                'Completion status should return to original (iteration $i)');
      }
    });

    test('Property: Multiple operations complete offline in sequence',
        () async {
      // Run 50 iterations with sequences of operations
      for (int i = 0; i < 50; i++) {
        // Create task
        final task = Task(
          title: faker.lorem.sentence(),
          priority: faker.randomGenerator.integer(5, min: 1),
          completed: false,
        );
        await storage.createTask(task);

        // Update task
        final updated = task.copyWith(
          title: faker.lorem.sentence(),
          priority: faker.randomGenerator.integer(5, min: 1),
        );
        await storage.updateTask(updated);

        // Toggle completion
        final completed = updated.copyWith(completed: true);
        await storage.updateTask(completed);

        // Verify all operations completed successfully
        final retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull,
            reason: 'Task should exist after sequence (iteration $i)');
        expect(retrieved!.id, equals(task.id),
            reason: 'Task ID should be preserved (iteration $i)');
        expect(retrieved.title, equals(updated.title),
            reason: 'Task should have updated title (iteration $i)');
        expect(retrieved.completed, isTrue,
            reason: 'Task should be completed (iteration $i)');

        // Delete task
        await storage.deleteTask(task.id);

        // Verify deletion
        final deletedCheck = await storage.getTaskById(task.id);
        expect(deletedCheck, isNull,
            reason: 'Task should be deleted (iteration $i)');
      }
    });

    test('Property: Task list loads offline with any number of tasks',
        () async {
      // Run 20 iterations with varying numbers of tasks
      for (int i = 0; i < 20; i++) {
        // Generate random number of tasks (0-20)
        final taskCount = faker.randomGenerator.integer(20, min: 0);
        final tasks = <Task>[];

        for (int j = 0; j < taskCount; j++) {
          final task = Task(
            title: faker.lorem.sentence(),
            priority: faker.randomGenerator.integer(5, min: 1),
            dueDate: faker.randomGenerator.boolean()
                ? DateTime.now().add(Duration(
                    days: faker.randomGenerator.integer(365, min: 1)))
                : null,
            completed: faker.randomGenerator.boolean(),
          );
          tasks.add(task);
          await storage.createTask(task);
        }

        // Load tasks from local storage (simulating offline)
        final loadedTasks = await storage.getAllTasks();

        // Verify operation completed successfully
        expect(loadedTasks.length, greaterThanOrEqualTo(taskCount),
            reason: 'All tasks should be loaded offline (iteration $i)');

        // Verify all created tasks are in the loaded list
        for (final task in tasks) {
          expect(loadedTasks.any((t) => t.id == task.id), isTrue,
              reason: 'Task ${task.id} should be in loaded list (iteration $i)');
        }

        // Clean up for next iteration
        for (final task in tasks) {
          await storage.deleteTask(task.id);
        }
        
        // Wait a bit to ensure all async operations complete
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });
  });
}
