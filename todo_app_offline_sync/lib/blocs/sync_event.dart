import 'package:equatable/equatable.dart';

/// Base class for all sync events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger syncing local tasks to the cloud
class SyncToCloud extends SyncEvent {
  const SyncToCloud();
}

/// Event to trigger downloading tasks from the cloud
class SyncFromCloud extends SyncEvent {
  const SyncFromCloud();
}

/// Event to resolve a sync conflict
class ResolveSyncConflict extends SyncEvent {
  final String taskId;
  final String resolution; // 'local' or 'remote'

  const ResolveSyncConflict({
    required this.taskId,
    required this.resolution,
  });

  @override
  List<Object?> get props => [taskId, resolution];
}
