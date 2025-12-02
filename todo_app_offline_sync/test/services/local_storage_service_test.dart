import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';
import 'dart:math';

void main() {
  // Initialize FFI for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Local Storage Service Property Tests', () {
    // Feature: todo-app-offline-sync, Property 2: Task creation increases local count
    // Validates: Requirements 1.1
    test('Property 2: Task creation increases local count', () async {
      final random = Random();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Create isolated database for each iteration
        final dbHelper = DatabaseHelper.test('test_create_count_${DateTime.now().millisecondsSinceEpoch}_$i.db');
        final service = LocalStorageService(dbHelper: dbHelper);

        // Get initial count
        final initialTasks = await service.getAllTasks();
        final initialCount = initialTasks.length;

        // Generate a random valid task
        final task = _generateRandomValidTask(random);

        // Create the task
        await service.createTask(task);

        // Get new count
        final finalTasks = await service.getAllTasks();
        final finalCount = finalTasks.length;

        // Verify count increased by exactly 1
        expect(
          finalCount,
          equals(initialCount + 1),
          reason:
              'Creating a task should increase the count by exactly 1 (iteration $i)',
        );

        service.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 3: Task unique identifier assignment
    // Validates: Requirements 1.4
    test('Property 3: Task unique identifier assignment', () async {
      final dbHelper = DatabaseHelper.test('test_unique_id_${DateTime.now().millisecondsSinceEpoch}.db');
      final service = LocalStorageService(dbHelper: dbHelper);
      
      try {
        final random = Random();
        const iterations = 100;

        // Create multiple tasks
        final createdIds = <String>{};

        for (int i = 0; i < iterations; i++) {
          final task = _generateRandomValidTask(random);
          await service.createTask(task);
          createdIds.add(task.id);
        }

        // Verify all IDs are unique
        expect(
          createdIds.length,
          equals(iterations),
          reason: 'All task IDs should be unique',
        );

        // Verify all tasks can be retrieved
        final allTasks = await service.getAllTasks();
        expect(
          allTasks.length,
          equals(iterations),
          reason: 'All created tasks should be retrievable',
        );

        // Verify no ID collisions
        final retrievedIds = allTasks.map((t) => t.id).toSet();
        expect(
          retrievedIds.length,
          equals(iterations),
          reason: 'No ID collisions should occur in storage',
        );
      } finally {
        service.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 16: Data persistence across restarts
    // Validates: Requirements 12.2, 12.3
    test('Property 16: Data persistence across restarts', () async {
      final random = Random();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Create isolated database for each iteration
        final dbName = 'test_persistence_${DateTime.now().millisecondsSinceEpoch}_$i.db';
        var dbHelper = DatabaseHelper.test(dbName);
        var testService = LocalStorageService(dbHelper: dbHelper);

        // Generate a random task
        final task = _generateRandomValidTask(random);

        // Create the task
        await testService.createTask(task);

        // Wait for async operations to complete before disposing
        await Future.delayed(const Duration(milliseconds: 50));

        // Simulate app restart by closing and reopening database
        testService.dispose();
        await Future.delayed(const Duration(milliseconds: 10)); // Wait for dispose to complete
        await dbHelper.close();

        // Create new service instance with same database (simulating restart)
        dbHelper = DatabaseHelper.test(dbName);
        testService = LocalStorageService(dbHelper: dbHelper);

        // Retrieve the task
        final retrievedTask = await testService.getTaskById(task.id);

        // Verify task was persisted
        expect(
          retrievedTask,
          isNotNull,
          reason: 'Task should persist across restart (iteration $i)',
        );

        // Verify all fields are identical
        expect(retrievedTask!.id, equals(task.id));
        expect(retrievedTask.title, equals(task.title));
        expect(retrievedTask.description, equals(task.description));
        expect(retrievedTask.priority, equals(task.priority));
        expect(retrievedTask.completed, equals(task.completed));

        // Compare timestamps
        expect(
          retrievedTask.createdAt.millisecondsSinceEpoch,
          equals(task.createdAt.millisecondsSinceEpoch),
        );
        expect(
          retrievedTask.updatedAt.millisecondsSinceEpoch,
          equals(task.updatedAt.millisecondsSinceEpoch),
        );

        // Compare due dates
        if (task.dueDate != null) {
          expect(
            retrievedTask.dueDate?.millisecondsSinceEpoch,
            equals(task.dueDate?.millisecondsSinceEpoch),
          );
        } else {
          expect(retrievedTask.dueDate, isNull);
        }

        testService.dispose();
        await dbHelper.close();
      }
    });
  });

  group('Local Storage Service Unit Tests', () {
    late LocalStorageService service;
    late DatabaseHelper dbHelper;

    setUp(() async {
      // Create isolated database for each test
      dbHelper = DatabaseHelper.test('test_unit_${DateTime.now().millisecondsSinceEpoch}.db');
      service = LocalStorageService(dbHelper: dbHelper);
    });

    tearDown(() async {
      service.dispose();
      await dbHelper.close();
    });

    test('getAllTasks returns empty list initially', () async {
      final tasks = await service.getAllTasks();
      expect(tasks, isEmpty);
    });

    test('createTask stores task correctly', () async {
      final task = Task(title: 'Test Task');
      await service.createTask(task);

      final tasks = await service.getAllTasks();
      expect(tasks.length, equals(1));
      expect(tasks.first.title, equals('Test Task'));
    });

    test('getTaskById returns correct task', () async {
      final task = Task(title: 'Test Task');
      await service.createTask(task);

      final retrieved = await service.getTaskById(task.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(task.id));
      expect(retrieved.title, equals('Test Task'));
    });

    test('getTaskById returns null for non-existent task', () async {
      final retrieved = await service.getTaskById('non-existent-id');
      expect(retrieved, isNull);
    });

    test('updateTask modifies existing task', () async {
      final task = Task(title: 'Original Title');
      await service.createTask(task);

      final updated = task.copyWith(title: 'Updated Title');
      await service.updateTask(updated);

      final retrieved = await service.getTaskById(task.id);
      expect(retrieved!.title, equals('Updated Title'));
    });

    test('deleteTask removes task', () async {
      final task = Task(title: 'Test Task');
      await service.createTask(task);

      await service.deleteTask(task.id);

      final retrieved = await service.getTaskById(task.id);
      expect(retrieved, isNull);
    });

    test('tasks are sorted by priority desc, then dueDate asc', () async {
      final now = DateTime.now();
      final task1 = Task(
        title: 'Low priority, early date',
        priority: 1,
        dueDate: now.add(const Duration(days: 1)),
      );
      final task2 = Task(
        title: 'High priority, late date',
        priority: 5,
        dueDate: now.add(const Duration(days: 10)),
      );
      final task3 = Task(
        title: 'High priority, early date',
        priority: 5,
        dueDate: now.add(const Duration(days: 2)),
      );

      await service.createTask(task1);
      await service.createTask(task2);
      await service.createTask(task3);

      final tasks = await service.getAllTasks();

      // Should be sorted: task3 (5, day 2), task2 (5, day 10), task1 (1, day 1)
      expect(tasks[0].id, equals(task3.id));
      expect(tasks[1].id, equals(task2.id));
      expect(tasks[2].id, equals(task1.id));
    });

    test('watchTasks emits updates on changes', () async {
      final stream = service.watchTasks();
      final emittedLists = <List<Task>>[];

      final subscription = stream.listen((tasks) {
        emittedLists.add(tasks);
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Create a task
      final task = Task(title: 'Test Task');
      await service.createTask(task);

      // Wait for emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify we got at least 2 emissions (initial + after create)
      expect(emittedLists.length, greaterThanOrEqualTo(2));
      expect(emittedLists.last.length, equals(1));

      await subscription.cancel();
    });
  });
}

/// Generates a random valid task for property-based testing
Task _generateRandomValidTask(Random random) {
  // Generate random title (non-empty, non-whitespace)
  final titleLength = random.nextInt(50) + 1;
  final title = _generateRandomNonWhitespaceString(random, titleLength);

  // Generate random description (50% chance of null)
  final description = random.nextBool()
      ? _generateRandomString(random, random.nextInt(200) + 1)
      : null;

  // Generate random priority (1-5)
  final priority = random.nextInt(5) + 1;

  // Generate random due date (50% chance of null, always in future)
  final dueDate = random.nextBool()
      ? DateTime.now().add(Duration(days: random.nextInt(365) + 1))
      : null;

  // Generate random completed status
  final completed = random.nextBool();

  // Generate random timestamps (in the past)
  final createdAt = DateTime.now().subtract(
    Duration(days: random.nextInt(100)),
  );
  final updatedAt = createdAt.add(
    Duration(hours: random.nextInt(24)),
  );

  return Task(
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
    completed: completed,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Generates a random string of specified length
String _generateRandomString(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Generates a random non-whitespace string (ensures valid title)
String _generateRandomNonWhitespaceString(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
