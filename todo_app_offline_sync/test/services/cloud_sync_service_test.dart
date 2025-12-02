import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:todo_app_offline_sync/models/task.dart';
import 'package:todo_app_offline_sync/services/cloud_sync_service.dart';

void main() {
  group('CloudSyncService Property Tests', () {
    late CloudSyncService cloudSyncService;
    final faker = Faker();

    setUp(() {
      cloudSyncService = CloudSyncService();
    });

    // Feature: todo-app-offline-sync, Property 13: Sync merge without duplicates
    // Validates: Requirements 9.4
    test(
        'Property 13: For any set of local and remote tasks with overlapping IDs, '
        'merging should result in each unique task ID appearing exactly once',
        () {
      // Run the property test 100 times with random data
      for (int i = 0; i < 100; i++) {
        // Generate random number of local tasks (0-20)
        final numLocalTasks = faker.randomGenerator.integer(20);
        final localTasks = <Task>[];

        for (int j = 0; j < numLocalTasks; j++) {
          localTasks.add(_generateRandomTask());
        }

        // Generate random number of remote tasks (0-20)
        final numRemoteTasks = faker.randomGenerator.integer(20);
        final remoteTasks = <Task>[];

        // Create some overlapping tasks (same ID but potentially different data)
        final numOverlapping =
            faker.randomGenerator.integer(numLocalTasks.clamp(0, 10));

        for (int j = 0; j < numOverlapping && j < localTasks.length; j++) {
          // Create a remote task with the same ID as a local task
          final localTask = localTasks[j];
          remoteTasks.add(
            localTask.copyWith(
              title: faker.lorem.sentence(),
              updatedAt: DateTime.now().add(
                Duration(seconds: faker.randomGenerator.integer(100)),
              ),
            ),
          );
        }

        // Add completely new remote tasks
        for (int j = numOverlapping; j < numRemoteTasks; j++) {
          remoteTasks.add(_generateRandomTask());
        }

        // Perform the merge
        final mergedTasks = cloudSyncService.mergeTasks(localTasks, remoteTasks);

        // Collect all unique IDs from local and remote
        final allIds = <String>{};
        allIds.addAll(localTasks.map((t) => t.id));
        allIds.addAll(remoteTasks.map((t) => t.id));

        // Property: Each unique task ID should appear exactly once in merged list
        final mergedIds = mergedTasks.map((t) => t.id).toList();
        final uniqueMergedIds = mergedIds.toSet();

        // Check 1: No duplicate IDs in merged list
        expect(
          mergedIds.length,
          equals(uniqueMergedIds.length),
          reason: 'Merged list should not contain duplicate IDs',
        );

        // Check 2: All unique IDs from both lists should be in merged list
        expect(
          uniqueMergedIds,
          equals(allIds),
          reason: 'Merged list should contain all unique IDs from both lists',
        );

        // Check 3: Merged list should have exactly the number of unique IDs
        expect(
          mergedTasks.length,
          equals(allIds.length),
          reason: 'Merged list length should equal number of unique IDs',
        );
      }
    });

    // Feature: todo-app-offline-sync, Property 14: Conflict resolution preserves latest
    // Validates: Requirements 9.5
    test(
        'Property 14: For any sync conflict where the same task was modified on multiple devices, '
        'the version with the most recent updatedAt timestamp should be kept',
        () {
      // Run the property test 100 times with random data
      for (int i = 0; i < 100; i++) {
        // Generate a base task
        final baseTask = _generateRandomTask();

        // Create two versions of the same task with different update times
        final localUpdatedAt = DateTime.now().subtract(
          Duration(seconds: faker.randomGenerator.integer(1000, min: 1)),
        );

        final remoteUpdatedAt = DateTime.now().subtract(
          Duration(seconds: faker.randomGenerator.integer(1000, min: 1)),
        );

        final localTask = baseTask.copyWith(
          title: 'Local: ${faker.lorem.sentence()}',
          updatedAt: localUpdatedAt,
        );

        final remoteTask = baseTask.copyWith(
          id: localTask.id, // Same ID to create conflict
          title: 'Remote: ${faker.lorem.sentence()}',
          updatedAt: remoteUpdatedAt,
        );

        // Determine which should win based on timestamp
        final expectedWinner =
            localUpdatedAt.isAfter(remoteUpdatedAt) ? localTask : remoteTask;

        // Perform the merge
        final mergedTasks =
            cloudSyncService.mergeTasks([localTask], [remoteTask]);

        // Property: The merged list should contain exactly one task with this ID
        expect(
          mergedTasks.length,
          equals(1),
          reason: 'Merged list should contain exactly one task',
        );

        final mergedTask = mergedTasks.first;

        // Property: The merged task should have the same ID
        expect(
          mergedTask.id,
          equals(baseTask.id),
          reason: 'Merged task should have the same ID as the conflicting tasks',
        );

        // Property: The merged task should be the one with the latest updatedAt
        expect(
          mergedTask.updatedAt,
          equals(expectedWinner.updatedAt),
          reason:
              'Merged task should have the updatedAt of the most recent version',
        );

        expect(
          mergedTask.title,
          equals(expectedWinner.title),
          reason: 'Merged task should have the title of the most recent version',
        );
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
