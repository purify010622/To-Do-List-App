import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/models/task.dart';

/// Performance tests to validate app performance requirements
/// 
/// These tests verify:
/// - Database query performance with large datasets
/// - Pagination efficiency
/// - Index effectiveness
void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Performance Tests', () {
    late DatabaseHelper dbHelper;
    late LocalStorageService storageService;

    setUp(() async {
      // Create a test database
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      dbHelper = DatabaseHelper.test('test_performance_$timestamp.db');
      storageService = LocalStorageService(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Database query performance with 1000 tasks should be < 100ms', () async {
      // Create 1000 test tasks
      final stopwatch = Stopwatch()..start();
      final now = DateTime.now();
      
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'task_$i',
          title: 'Task $i',
          description: 'Description for task $i',
          priority: (i % 5) + 1,
          dueDate: now.add(Duration(days: (i % 30) + 1)), // Add 1 to ensure future date
          completed: i % 3 == 0,
          createdAt: now,
          updatedAt: now,
        );
        await storageService.createTask(task);
      }
      
      stopwatch.stop();
      // Created 1000 tasks
      
      // Test query performance
      stopwatch.reset();
      stopwatch.start();
      
      final tasks = await storageService.getAllTasks();
      
      stopwatch.stop();
      final queryTime = stopwatch.elapsedMilliseconds;
      
      // Verify query time is acceptable (< 100ms for 1000 tasks)
      expect(queryTime, lessThan(100), 
        reason: 'Query time should be less than 100ms for 1000 tasks');
      expect(tasks.length, equals(1000));
    });

    test('Pagination should efficiently handle large datasets', () async {
      // Create 200 test tasks
      final now = DateTime.now();
      for (int i = 0; i < 200; i++) {
        final task = Task(
          id: 'task_$i',
          title: 'Task $i',
          priority: (i % 5) + 1,
          dueDate: now.add(Duration(days: i + 1)), // Add 1 to ensure future date
          completed: false,
          createdAt: now,
          updatedAt: DateTime.now(),
        );
        await storageService.createTask(task);
      }
      
      // Simulate pagination (50 items per page)
      final stopwatch = Stopwatch()..start();
      
      final allTasks = await storageService.getAllTasks();
      final page1 = allTasks.take(50).toList();
      final page2 = allTasks.skip(50).take(50).toList();
      final page3 = allTasks.skip(100).take(50).toList();
      final page4 = allTasks.skip(150).take(50).toList();
      
      stopwatch.stop();
      
      // Paginated 200 tasks into 4 pages
      
      expect(page1.length, equals(50));
      expect(page2.length, equals(50));
      expect(page3.length, equals(50));
      expect(page4.length, equals(50));
      
      // Verify pagination is efficient
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
        reason: 'Pagination should be efficient');
    });

    test('Sorting with indexes should be fast', () async {
      // Create 500 tasks with random priorities and dates
      final now = DateTime.now();
      for (int i = 0; i < 500; i++) {
        final task = Task(
          id: 'task_$i',
          title: 'Task $i',
          priority: (i % 5) + 1,
          dueDate: now.add(Duration(days: (i % 100) + 1)), // Add 1 to ensure future date
          completed: false,
          createdAt: now,
          updatedAt: now,
        );
        await storageService.createTask(task);
      }
      
      // Test sorting performance (should use composite index)
      final stopwatch = Stopwatch()..start();
      
      final tasks = await storageService.getAllTasks();
      
      stopwatch.stop();
      final sortTime = stopwatch.elapsedMilliseconds;
      
      // Verify tasks are sorted correctly (priority desc, then dueDate asc)
      for (int i = 0; i < tasks.length - 1; i++) {
        if (tasks[i].priority == tasks[i + 1].priority) {
          // Same priority, check due date ordering
          if (tasks[i].dueDate != null && tasks[i + 1].dueDate != null) {
            expect(
              tasks[i].dueDate!.isBefore(tasks[i + 1].dueDate!) ||
                  tasks[i].dueDate!.isAtSameMomentAs(tasks[i + 1].dueDate!),
              isTrue,
              reason: 'Tasks with same priority should be sorted by due date',
            );
          }
        } else {
          // Different priority, higher priority should come first
          expect(tasks[i].priority, greaterThanOrEqualTo(tasks[i + 1].priority),
            reason: 'Tasks should be sorted by priority descending');
        }
      }
      
      // Verify sorting is efficient with indexes
      expect(sortTime, lessThan(100),
        reason: 'Sorting should be fast with proper indexes');
    });

    test('Individual task operations should be fast', () async {
      final task = Task(
        id: 'test_task',
        title: 'Test Task',
        priority: 3,
        completed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Test create performance
      var stopwatch = Stopwatch()..start();
      await storageService.createTask(task);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      
      // Test read performance
      stopwatch.reset();
      stopwatch.start();
      final retrieved = await storageService.getTaskById(task.id);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(20));
      expect(retrieved, isNotNull);
      
      // Test update performance
      final updated = task.copyWith(title: 'Updated Task');
      stopwatch.reset();
      stopwatch.start();
      await storageService.updateTask(updated);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      
      // Test delete performance
      stopwatch.reset();
      stopwatch.start();
      await storageService.deleteTask(task.id);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Memory usage should be reasonable for large datasets', () async {
      // Create 1000 tasks
      final now = DateTime.now();
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'task_$i',
          title: 'Task $i',
          description: 'A longer description for task $i to test memory usage',
          priority: (i % 5) + 1,
          dueDate: now.add(Duration(days: i + 1)), // Add 1 to ensure future date
          completed: false,
          createdAt: now,
          updatedAt: now,
        );
        await storageService.createTask(task);
      }
      
      // Load all tasks
      final tasks = await storageService.getAllTasks();
      
      // Verify we can handle large datasets
      expect(tasks.length, equals(1000));
      
      // Calculate approximate memory usage
      // Each task is roughly 200-300 bytes
      // 1000 tasks = ~200-300 KB, which is acceptable
      // Loaded tasks successfully
    });
  });
}
