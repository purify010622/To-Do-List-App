import 'package:equatable/equatable.dart';
import '../models/task.dart';

/// Base class for all sync states
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no sync operation in progress
class SyncIdle extends SyncState {
  final DateTime? lastSyncTime;

  const SyncIdle({this.lastSyncTime});

  @override
  List<Object?> get props => [lastSyncTime];
}

/// Sync operation is in progress
class SyncInProgress extends SyncState {
  final double progress; // 0.0 to 1.0
  final String message;

  const SyncInProgress({
    required this.progress,
    this.message = 'Syncing...',
  });

  @override
  List<Object?> get props => [progress, message];
}

/// Sync operation completed successfully
class SyncComplete extends SyncState {
  final DateTime syncTime;
  final int tasksSynced;

  const SyncComplete({
    required this.syncTime,
    required this.tasksSynced,
  });

  @override
  List<Object?> get props => [syncTime, tasksSynced];
}

/// Sync conflict detected - requires user resolution
class SyncConflict extends SyncState {
  final List<Task> conflictingTasks;
  final String message;

  const SyncConflict({
    required this.conflictingTasks,
    this.message = 'Sync conflicts detected',
  });

  @override
  List<Object?> get props => [conflictingTasks, message];
}

/// Sync operation failed
class SyncError extends SyncState {
  final String message;
  final dynamic error;

  const SyncError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}
