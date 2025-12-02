import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';

/// Test that all operations work offline (without network connectivity)
void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Operations', () {
    test('Task creation works offline', () async {
      final dbHelper = DatabaseHelper.test('test_offline_create_${DateTime.now().millisecondsSinceEpoch}.db');
      final storage = LocalStorageService(dbHelper: dbHelper);
      
      try {
      // Create a task without network
      final task = Task(
        title: 'Offline Task',
        description: 'Created without internet',
        priority: 3,
      );

      await storage.createTask(task);

        // Verify task was created
        final tasks = await storage.getAllTasks();
        expect(tasks.length, greaterThan(0));
        expect(tasks.any((t) => t.id == task.id), isTrue);
      } finally {
        storage.dispose();
        await dbHelper.close();
      }
    });

    test('Task editing works offline', () async {
      final dbHelper = DatabaseHelper.test('test_offline_edit_${DateTime.now().millisecondsSinceEpoch}.db');
      final storage = LocalStorageService(dbHelper: dbHelper);
      
      try {
      // Create a task
      final task = Task(
        title: 'Original Title',
        priority: 2,
      );
      await storage.createTask(task);

      // Edit the task offline
      final updatedTask = task.copyWith(
        title: 'Updated Title',
        priority: 4,
      );
      await storage.updateTask(updatedTask);

        // Verify task was updated
        final retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Updated Title'));
        expect(retrieved.priority, equals(4));
        expect(retrieved.id, equals(task.id)); // ID should be preserved
      } finally {
        storage.dispose();
        await dbHelper.close();
      }
    });

    test('Task deletion works offline', () async {
      final dbHelper = DatabaseHelper.test('test_offline_delete_${DateTime.now().millisecondsSinceEpoch}.db');
      final storage = LocalStorageService(dbHelper: dbHelper);
      
      try {
      // Create a task
      final task = Task(
        title: 'Task to Delete',
        priority: 1,
      );
      await storage.createTask(task);

      // Verify task exists
      var retrieved = await storage.getTaskById(task.id);
      expect(retrieved, isNotNull);

      // Delete the task offline
      await storage.deleteTask(task.id);

        // Verify task was deleted
        retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNull);
      } finally {
        storage.dispose();
        await dbHelper.close();
      }
    });

    test('Completion toggle works offline', () async {
      final dbHelper = DatabaseHelper.test('test_offline_toggle_${DateTime.now().millisecondsSinceEpoch}.db');
      final storage = LocalStorageService(dbHelper: dbHelper);
      
      try {
      // Create a task
      final task = Task(
        title: 'Task to Complete',
        completed: false,
      );
      await storage.createTask(task);

      // Toggle completion offline
      final completedTask = task.copyWith(completed: true);
      await storage.updateTask(completedTask);

      // Verify completion status changed
      var retrieved = await storage.getTaskById(task.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.completed, isTrue);

      // Toggle back
      final uncompletedTask = completedTask.copyWith(completed: false);
      await storage.updateTask(uncompletedTask);

        retrieved = await storage.getTaskById(task.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.completed, isFalse);
      } finally {
        storage.dispose();
        await dbHelper.close();
      }
    });

    test('Task list loads from local storage when offline', () async {
      final dbHelper = DatabaseHelper.test('test_offline_list_${DateTime.now().millisecondsSinceEpoch}.db');
      final storage = LocalStorageService(dbHelper: dbHelper);
      
      try {
      // Create multiple tasks
      final tasks = [
        Task(title: 'Task 1', priority: 5),
        Task(title: 'Task 2', priority: 3),
        Task(title: 'Task 3', priority: 1),
      ];

      for (final task in tasks) {
        await storage.createTask(task);
      }

      // Load tasks from local storage (simulating offline)
      final loadedTasks = await storage.getAllTasks();

      // Verify all tasks are loaded
      expect(loadedTasks.length, greaterThanOrEqualTo(tasks.length));
      for (final task in tasks) {
        expect(loadedTasks.any((t) => t.id == task.id), isTrue);
      }

        // Verify tasks are sorted by priority (desc)
        for (int i = 0; i < loadedTasks.length - 1; i++) {
          expect(
            loadedTasks[i].priority,
            greaterThanOrEqualTo(loadedTasks[i + 1].priority),
          );
        }
      } finally {
        storage.dispose();
        await dbHelper.close();
      }
    });
  });
}
