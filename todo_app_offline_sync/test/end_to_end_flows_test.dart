import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/utils/validators.dart';

/// End-to-end flow tests for task operations
/// These tests verify complete user workflows without requiring UI
void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Guest User Flow Tests', () {
    late LocalStorageService repository;

    setUp(() async {
      repository = LocalStorageService();
      
      // Clear any existing tasks
      final tasks = await repository.getAllTasks();
      for (final task in tasks) {
        await repository.deleteTask(task.id);
      }
    });

    test('Complete guest user flow: create → edit → complete → delete', () async {
      // Step 1: Create a task
      final task = Task(
        title: 'Test Task',
        description: 'This is a test task',
        priority: 4,
        completed: false,
      );

      await repository.createTask(task);

      // Verify task was created
      final allTasks = await repository.getAllTasks();
      expect(allTasks.length, 1);
      expect(allTasks[0].title, 'Test Task');
      expect(allTasks[0].priority, 4);
      expect(allTasks[0].completed, false);

      // Step 2: Edit the task
      final updatedTask = allTasks[0].copyWith(
        title: 'Updated Test Task',
        priority: 5,
      );

      await repository.updateTask(updatedTask);

      // Verify task was updated
      final updatedTasks = await repository.getAllTasks();
      expect(updatedTasks.length, 1);
      expect(updatedTasks[0].title, 'Updated Test Task');
      expect(updatedTasks[0].priority, 5);
      expect(updatedTasks[0].id, task.id); // ID should remain the same

      // Step 3: Complete the task
      final completedTask = updatedTasks[0].copyWith(completed: true);
      await repository.updateTask(completedTask);

      // Verify task was completed
      final completedTasks = await repository.getAllTasks();
      expect(completedTasks.length, 1);
      expect(completedTasks[0].completed, true);

      // Step 4: Delete the task
      await repository.deleteTask(completedTask.id);

      // Verify task was deleted
      final finalTasks = await repository.getAllTasks();
      expect(finalTasks.length, 0);
    });

    test('Empty title validation prevents task creation', () async {
      // Attempt to create a task with empty title
      expect(validateTitle(''), false);
      expect(validateTitle('   '), false);
      expect(validateTitle('\t\n'), false);

      // Valid titles should pass
      expect(validateTitle('Valid Task'), true);
      expect(validateTitle('  Valid Task  '), true);
    });

    test('Priority validation enforces bounds', () async {
      // Invalid priorities
      expect(validatePriority(0), false);
      expect(validatePriority(6), false);
      expect(validatePriority(-1), false);
      expect(validatePriority(100), false);

      // Valid priorities
      expect(validatePriority(1), true);
      expect(validatePriority(2), true);
      expect(validatePriority(3), true);
      expect(validatePriority(4), true);
      expect(validatePriority(5), true);
    });

    test('Due date validation rejects past dates', () async {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));
      final futureDate = now.add(const Duration(days: 1));

      expect(validateDueDate(pastDate), false);
      expect(validateDueDate(futureDate), true);
    });

    test('Task sorting by priority and due date', () async {
      // Create tasks with different priorities and due dates
      final now = DateTime.now();
      
      final task1 = Task(
        title: 'Low Priority Task',
        priority: 2,
        dueDate: now.add(const Duration(days: 1)),
      );
      
      final task2 = Task(
        title: 'High Priority Task',
        priority: 5,
        dueDate: now.add(const Duration(days: 2)),
      );
      
      final task3 = Task(
        title: 'Medium Priority Task',
        priority: 3,
        dueDate: now.add(const Duration(hours: 12)),
      );

      await repository.createTask(task1);
      await repository.createTask(task2);
      await repository.createTask(task3);

      // Get all tasks (should be sorted by priority desc, then due date asc)
      final tasks = await repository.getAllTasks();

      // Verify sorting: High (5), Medium (3), Low (2)
      expect(tasks.length, 3);
      expect(tasks[0].priority, 5); // High priority first
      expect(tasks[1].priority, 3); // Medium priority second
      expect(tasks[2].priority, 2); // Low priority last
    });

    test('Completion toggle idempotence', () async {
      // Create a task
      final task = Task(
        title: 'Toggle Test Task',
        completed: false,
      );

      await repository.createTask(task);

      // Toggle completion twice
      final task1 = (await repository.getAllTasks())[0];
      final toggledOnce = task1.copyWith(completed: !task1.completed);
      await repository.updateTask(toggledOnce);

      final task2 = (await repository.getAllTasks())[0];
      final toggledTwice = task2.copyWith(completed: !task2.completed);
      await repository.updateTask(toggledTwice);

      // Verify we're back to original state
      final finalTask = (await repository.getAllTasks())[0];
      expect(finalTask.completed, task.completed);
    });

    test('Task update preserves identity', () async {
      // Create a task
      final task = Task(
        title: 'Original Task',
        description: 'Original description',
        priority: 3,
      );

      await repository.createTask(task);
      final originalId = task.id;

      // Update multiple fields
      final updatedTask = task.copyWith(
        title: 'Updated Task',
        description: 'Updated description',
        priority: 5,
      );

      await repository.updateTask(updatedTask);

      // Verify ID is preserved
      final retrievedTask = await repository.getTaskById(originalId);
      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.id, originalId);
      expect(retrievedTask.title, 'Updated Task');
      expect(retrievedTask.description, 'Updated description');
      expect(retrievedTask.priority, 5);
    });

    test('Deletion removes task completely', () async {
      // Create a task
      final task = Task(title: 'Task to Delete');
      await repository.createTask(task);

      // Verify task exists
      final taskBefore = await repository.getTaskById(task.id);
      expect(taskBefore, isNotNull);

      // Delete the task
      await repository.deleteTask(task.id);

      // Verify task is completely removed
      final taskAfter = await repository.getTaskById(task.id);
      expect(taskAfter, isNull);
    });
  });

  group('Offline Operations Tests', () {
    late LocalStorageService repository;

    setUp(() async {
      repository = LocalStorageService();
      
      // Clear any existing tasks
      final tasks = await repository.getAllTasks();
      for (final task in tasks) {
        await repository.deleteTask(task.id);
      }
    });

    test('All operations work without network connectivity', () async {
      // This test simulates offline operation by not using any network services
      
      // Create task offline
      final task = Task(
        title: 'Offline Task',
        description: 'Created while offline',
        priority: 3,
      );
      await repository.createTask(task);

      // Verify creation worked
      var tasks = await repository.getAllTasks();
      expect(tasks.length, 1);

      // Update task offline
      final updatedTask = tasks[0].copyWith(
        title: 'Updated Offline Task',
        completed: true,
      );
      await repository.updateTask(updatedTask);

      // Verify update worked
      tasks = await repository.getAllTasks();
      expect(tasks[0].title, 'Updated Offline Task');
      expect(tasks[0].completed, true);

      // Delete task offline
      await repository.deleteTask(tasks[0].id);

      // Verify deletion worked
      tasks = await repository.getAllTasks();
      expect(tasks.length, 0);
    });

    test('Data persists across repository instances', () async {
      // Create a task with first repository instance
      final task = Task(
        title: 'Persistent Task',
        priority: 4,
      );
      await repository.createTask(task);

      // Create a new repository instance (simulates app restart)
      final newRepository = LocalStorageService();

      // Verify task persists
      final tasks = await newRepository.getAllTasks();
      expect(tasks.length, 1);
      expect(tasks[0].title, 'Persistent Task');
      expect(tasks[0].priority, 4);
      expect(tasks[0].id, task.id);
    });
  });
}
