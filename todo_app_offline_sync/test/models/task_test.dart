import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'dart:math';

void main() {
  group('Task Model Tests', () {
    // Feature: todo-app-offline-sync, Property 1: Task serialization round-trip
    // Validates: Requirements 1.1, 1.3
    test('Property 1: Task serialization round-trip', () {
      final random = Random();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random task data
        final task = _generateRandomTask(random);

        // Serialize to JSON
        final json = task.toJson();

        // Deserialize from JSON
        final deserializedTask = Task.fromJson(json);

        // Verify round-trip preserves all fields
        expect(deserializedTask.id, equals(task.id),
            reason: 'ID should be preserved in round-trip');
        expect(deserializedTask.title, equals(task.title),
            reason: 'Title should be preserved in round-trip');
        expect(deserializedTask.description, equals(task.description),
            reason: 'Description should be preserved in round-trip');
        expect(deserializedTask.priority, equals(task.priority),
            reason: 'Priority should be preserved in round-trip');
        expect(deserializedTask.completed, equals(task.completed),
            reason: 'Completed status should be preserved in round-trip');

        // Compare dates with tolerance for serialization precision
        if (task.dueDate != null) {
          expect(
            deserializedTask.dueDate?.toIso8601String(),
            equals(task.dueDate?.toIso8601String()),
            reason: 'Due date should be preserved in round-trip',
          );
        } else {
          expect(deserializedTask.dueDate, isNull,
              reason: 'Null due date should remain null');
        }

        expect(
          deserializedTask.createdAt.toIso8601String(),
          equals(task.createdAt.toIso8601String()),
          reason: 'Created at should be preserved in round-trip',
        );

        expect(
          deserializedTask.updatedAt.toIso8601String(),
          equals(task.updatedAt.toIso8601String()),
          reason: 'Updated at should be preserved in round-trip',
        );
      }
    });

    test('Task validation - valid title', () {
      expect(Task.isValidTitle('Valid Title'), isTrue);
      expect(Task.isValidTitle('A'), isTrue);
    });

    test('Task validation - invalid title', () {
      expect(Task.isValidTitle(''), isFalse);
      expect(Task.isValidTitle('   '), isFalse);
      expect(Task.isValidTitle('\t\n'), isFalse);
    });

    test('Task validation - valid priority', () {
      expect(Task.isValidPriority(1), isTrue);
      expect(Task.isValidPriority(3), isTrue);
      expect(Task.isValidPriority(5), isTrue);
    });

    test('Task validation - invalid priority', () {
      expect(Task.isValidPriority(0), isFalse);
      expect(Task.isValidPriority(6), isFalse);
      expect(Task.isValidPriority(-1), isFalse);
    });

    test('Task validation - valid due date', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      expect(Task.isValidDueDate(futureDate), isTrue);
    });

    test('Task validation - invalid due date', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      expect(Task.isValidDueDate(pastDate), isFalse);
    });

    test('Task creation with defaults', () {
      final task = Task(title: 'Test Task');
      expect(task.priority, equals(3));
      expect(task.completed, isFalse);
      expect(task.id, isNotEmpty);
    });

    test('Task copyWith preserves unchanged fields', () {
      final original = Task(
        title: 'Original',
        description: 'Description',
        priority: 2,
      );

      final updated = original.copyWith(title: 'Updated');

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated'));
      expect(updated.description, equals(original.description));
      expect(updated.priority, equals(original.priority));
    });

    test('Task creation throws on empty title', () {
      expect(
        () => Task(title: ''),
        throwsArgumentError,
      );
      expect(
        () => Task(title: '   '),
        throwsArgumentError,
      );
    });

    test('Task creation throws on invalid priority', () {
      expect(
        () => Task(title: 'Test', priority: 0),
        throwsArgumentError,
      );
      expect(
        () => Task(title: 'Test', priority: 6),
        throwsArgumentError,
      );
    });

    test('Task creation throws on past due date', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      expect(
        () => Task(title: 'Test', dueDate: pastDate),
        throwsArgumentError,
      );
    });
  });
}

/// Generates a random task for property-based testing
Task _generateRandomTask(Random random) {
  // Generate random title (non-empty)
  final titleLength = random.nextInt(50) + 1;
  final title = _generateRandomString(random, titleLength);

  // Generate random description (50% chance of null)
  final description = random.nextBool()
      ? _generateRandomString(random, random.nextInt(200))
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
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
