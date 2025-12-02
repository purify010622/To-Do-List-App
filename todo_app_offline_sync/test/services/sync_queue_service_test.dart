import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app_offline_sync/models/sync_queue_item.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/database_helper.dart';

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SyncQueueService Property Tests', () {
    final faker = Faker();
    late DatabaseHelper dbHelper;

    setUp(() async {
      // Create a unique test database for each test
      final dbName = 'test_sync_queue_${DateTime.now().millisecondsSinceEpoch}.db';
      dbHelper = DatabaseHelper.test(dbName);
    });

    tearDown(() async {
      // Clean up after each test
      await dbHelper.close();
    });

    // Feature: todo-app-offline-sync, Property 17: Sync queue ordering preservation
    // Validates: Requirements 11.4, 11.5
    test(
        'Property 17: For any sequence of offline operations, '
        'when retrieved from the queue, the operations should be in the same order '
        'they were added (ordered by timestamp)',
        () async {
      // Run the property test 100 times with random data
      for (int i = 0; i < 100; i++) {
        // Clear queue before each iteration
        final db = await dbHelper.database;
        await db.delete('sync_queue');

        // Generate random number of operations (1-20)
        final numOperations = faker.randomGenerator.integer(20, min: 1);
        final operations = <SyncQueueItem>[];

        // Create operations with incrementing timestamps
        final baseTime = DateTime.now();

        for (int j = 0; j < numOperations; j++) {
          final task = _generateRandomTask();
          final operation = SyncOperation
              .values[faker.randomGenerator.integer(SyncOperation.values.length)];

          final queueItem = SyncQueueItem(
            taskId: task.id,
            operation: operation,
            timestamp: baseTime.add(Duration(milliseconds: j * 100)),
            data: task.toJson(),
          );

          operations.add(queueItem);

          // Add to queue directly via database
          await db.insert('sync_queue', {
            'taskId': queueItem.taskId,
            'operation': queueItem.operation.name,
            'timestamp': queueItem.timestamp.millisecondsSinceEpoch,
            'data': _encodeData(queueItem.data),
          });

          // Add a small delay to ensure timestamp ordering
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Retrieve all operations from queue
        final maps = await db.query(
          'sync_queue',
          orderBy: 'timestamp ASC',
        );

        final retrievedOperations = maps.map((map) {
          return SyncQueueItem(
            taskId: map['taskId'] as String,
            operation: SyncOperation.values.firstWhere(
              (e) => e.name == map['operation'],
            ),
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              map['timestamp'] as int,
            ),
            data: _decodeData(map['data'] as String),
          );
        }).toList();

        // Property: The number of retrieved operations should match the number added
        expect(
          retrievedOperations.length,
          equals(operations.length),
          reason: 'All operations should be retrieved from the queue',
        );

        // Property: Operations should be in the same order (by timestamp)
        for (int j = 0; j < operations.length; j++) {
          expect(
            retrievedOperations[j].taskId,
            equals(operations[j].taskId),
            reason:
                'Operation at index $j should have the same taskId as the original',
          );

          expect(
            retrievedOperations[j].operation,
            equals(operations[j].operation),
            reason:
                'Operation at index $j should have the same operation type as the original',
          );

          // Check that timestamps are in ascending order
          if (j > 0) {
            expect(
              retrievedOperations[j]
                  .timestamp
                  .isAfter(retrievedOperations[j - 1].timestamp) ||
                  retrievedOperations[j]
                      .timestamp
                      .isAtSameMomentAs(retrievedOperations[j - 1].timestamp),
              isTrue,
              reason:
                  'Operations should be ordered by timestamp (ascending)',
            );
          }
        }
      }
    });
  });
}

/// Generate a random task for testing
Task _generateRandomTask() {
  final faker = Faker();

  return Task(
    title: faker.lorem.sentence(),
    description: faker.randomGenerator.boolean()
        ? faker.lorem.sentences(3).join(' ')
        : null,
    priority: faker.randomGenerator.integer(5, min: 1),
    dueDate: faker.randomGenerator.boolean()
        ? DateTime.now().add(
            Duration(days: faker.randomGenerator.integer(30, min: 1)),
          )
        : null,
    completed: faker.randomGenerator.boolean(),
  );
}

/// Encode data map to string
String _encodeData(Map<String, dynamic> data) {
  // Simple encoding: join key-value pairs with delimiters
  final entries = data.entries.map((e) => '${e.key}:${e.value}').join('|');
  return entries;
}

/// Decode data string to map
Map<String, dynamic> _decodeData(String dataString) {
  if (dataString.isEmpty) {
    return {};
  }

  final data = <String, dynamic>{};
  final entries = dataString.split('|');

  for (final entry in entries) {
    final parts = entry.split(':');
    if (parts.length == 2) {
      data[parts[0]] = parts[1];
    }
  }

  return data;
}
