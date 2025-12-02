import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/utils/validators.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/local_storage_service.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';
import 'dart:math';

void main() {
  // Initialize FFI for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Validation Property Tests', () {
    // Feature: todo-app-offline-sync, Property 2: Empty title rejection preserves state
    // Validates: Requirements 1.2, 4.5
    test('Property 2: Empty title rejection preserves state', () async {
      final dbHelper = DatabaseHelper.test('test_empty_title_${DateTime.now().millisecondsSinceEpoch}.db');
      final service = LocalStorageService(dbHelper: dbHelper);
      
      try {
        final random = Random();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Get initial task count
          final initialTasks = await service.getAllTasks();
          final initialCount = initialTasks.length;

        // Generate a whitespace-only or empty string
        final invalidTitle = _generateWhitespaceString(random);

        // Verify the title is invalid
        expect(validateTitle(invalidTitle), isFalse,
            reason: 'Generated string should be invalid: "$invalidTitle"');

        // Attempt to create a task with invalid title
        try {
          final task = Task(title: invalidTitle);
          await service.createTask(task);
          
          // If we get here, the validation failed to reject the invalid title
          fail('Task creation should have thrown an error for invalid title: "$invalidTitle"');
        } catch (e) {
          // Expected: task creation should fail
          expect(e, isA<ArgumentError>(),
              reason: 'Should throw ArgumentError for invalid title');
        }

        // Verify task count hasn't changed (state preserved)
        final finalTasks = await service.getAllTasks();
        final finalCount = finalTasks.length;

          expect(finalCount, equals(initialCount),
              reason: 'Task count should remain unchanged after rejected creation');
        }
      } finally {
        service.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 4: Priority level bounds validation
    // Validates: Requirements 2.1
    test('Property 4: Priority level bounds validation', () async {
      final dbHelper = DatabaseHelper.test('test_priority_${DateTime.now().millisecondsSinceEpoch}.db');
      final service = LocalStorageService(dbHelper: dbHelper);
      
      try {
        final random = Random();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Get initial task count
          final initialTasks = await service.getAllTasks();
          final initialCount = initialTasks.length;

          // Generate an invalid priority (outside 1-5 range)
        final invalidPriority = _generateInvalidPriority(random);

        // Verify the priority is invalid
        expect(validatePriority(invalidPriority), isFalse,
            reason: 'Generated priority should be invalid: $invalidPriority');

        // Attempt to create a task with invalid priority
        try {
          final task = Task(
            title: 'Test Task ${random.nextInt(10000)}',
            priority: invalidPriority,
          );
          await service.createTask(task);

          // If we get here, the validation failed to reject the invalid priority
          fail('Task creation should have thrown an error for invalid priority: $invalidPriority');
        } catch (e) {
          // Expected: task creation should fail
          expect(e, isA<ArgumentError>(),
              reason: 'Should throw ArgumentError for invalid priority');
        }

        // Verify task count hasn't changed (state preserved)
        final finalTasks = await service.getAllTasks();
        final finalCount = finalTasks.length;

          expect(finalCount, equals(initialCount),
              reason: 'Task count should remain unchanged after rejected creation');
        }
      } finally {
        service.dispose();
        await dbHelper.close();
      }
    });

    // Feature: todo-app-offline-sync, Property 5: Past due date rejection
    // Validates: Requirements 2.3
    test('Property 5: Past due date rejection', () async {
      final dbHelper = DatabaseHelper.test('test_past_date_${DateTime.now().millisecondsSinceEpoch}.db');
      final service = LocalStorageService(dbHelper: dbHelper);
      
      try {
        final random = Random();
        const iterations = 100;

        for (int i = 0; i < iterations; i++) {
          // Get initial task count
          final initialTasks = await service.getAllTasks();
          final initialCount = initialTasks.length;

        // Generate a past date
        final pastDate = _generatePastDate(random);

        // Verify the date is invalid
        expect(validateDueDate(pastDate), isFalse,
            reason: 'Generated date should be in the past: $pastDate');

        // Attempt to create a task with past due date
        try {
          final task = Task(
            title: 'Test Task ${random.nextInt(10000)}',
            dueDate: pastDate,
          );
          await service.createTask(task);

          // If we get here, the validation failed to reject the past date
          fail('Task creation should have thrown an error for past due date: $pastDate');
        } catch (e) {
          // Expected: task creation should fail
          expect(e, isA<ArgumentError>(),
              reason: 'Should throw ArgumentError for past due date');
        }

        // Verify task count hasn't changed (state preserved)
        final finalTasks = await service.getAllTasks();
        final finalCount = finalTasks.length;

          expect(finalCount, equals(initialCount),
              reason: 'Task count should remain unchanged after rejected creation');
        }
      } finally {
        service.dispose();
        await dbHelper.close();
      }
    });
  });

  group('Validation Unit Tests', () {
    test('validateTitle accepts valid titles', () {
      expect(validateTitle('Valid Title'), isTrue);
      expect(validateTitle('A'), isTrue);
      expect(validateTitle('  Valid with spaces  '), isTrue);
      expect(validateTitle('123'), isTrue);
    });

    test('validateTitle rejects invalid titles', () {
      expect(validateTitle(''), isFalse);
      expect(validateTitle('   '), isFalse);
      expect(validateTitle('\t'), isFalse);
      expect(validateTitle('\n'), isFalse);
      expect(validateTitle('  \t\n  '), isFalse);
    });

    test('validatePriority accepts valid priorities', () {
      expect(validatePriority(1), isTrue);
      expect(validatePriority(2), isTrue);
      expect(validatePriority(3), isTrue);
      expect(validatePriority(4), isTrue);
      expect(validatePriority(5), isTrue);
    });

    test('validatePriority rejects invalid priorities', () {
      expect(validatePriority(0), isFalse);
      expect(validatePriority(-1), isFalse);
      expect(validatePriority(6), isFalse);
      expect(validatePriority(100), isFalse);
      expect(validatePriority(-100), isFalse);
    });

    test('validateDueDate accepts future dates', () {
      final futureDate = DateTime.now().add(const Duration(seconds: 1));
      expect(validateDueDate(futureDate), isTrue);

      final farFuture = DateTime.now().add(const Duration(days: 365));
      expect(validateDueDate(farFuture), isTrue);
    });

    test('validateDueDate rejects past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(seconds: 1));
      expect(validateDueDate(pastDate), isFalse);

      final farPast = DateTime.now().subtract(const Duration(days: 365));
      expect(validateDueDate(farPast), isFalse);
    });

    test('ValidationErrors constants are defined', () {
      expect(ValidationErrors.emptyTitle, isNotEmpty);
      expect(ValidationErrors.invalidPriority, isNotEmpty);
      expect(ValidationErrors.pastDueDate, isNotEmpty);
    });
  });
}

/// Generates a whitespace-only or empty string for testing
String _generateWhitespaceString(Random random) {
  final types = [
    '', // empty string
    ' ', // single space
    '   ', // multiple spaces
    '\t', // tab
    '\n', // newline
    '  \t  ', // mixed whitespace
    '\t\n\t', // mixed whitespace
    '     \n     ', // spaces and newline
  ];
  return types[random.nextInt(types.length)];
}

/// Generates an invalid priority value (outside 1-5 range)
int _generateInvalidPriority(Random random) {
  // Generate either a value below 1 or above 5
  if (random.nextBool()) {
    // Below 1: generate from -100 to 0
    return random.nextInt(101) - 100;
  } else {
    // Above 5: generate from 6 to 100
    return random.nextInt(95) + 6;
  }
}

/// Generates a past date for testing
DateTime _generatePastDate(Random random) {
  // Generate a date from 1 second to 365 days in the past
  final secondsInPast = random.nextInt(365 * 24 * 60 * 60) + 1;
  return DateTime.now().subtract(Duration(seconds: secondsInPast));
}
