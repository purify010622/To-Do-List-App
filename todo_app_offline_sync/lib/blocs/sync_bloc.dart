import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/task_repository.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC for managing sync operations
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final TaskRepository taskRepository;
  final CloudSyncService cloudSyncService;
  final AuthService authService;

  SyncBloc({
    required this.taskRepository,
    required this.cloudSyncService,
    required this.authService,
  }) : super(const SyncIdle()) {
    on<SyncToCloud>(_onSyncToCloud);
    on<SyncFromCloud>(_onSyncFromCloud);
    on<ResolveSyncConflict>(_onResolveSyncConflict);
  }

  /// Handle syncing local tasks to the cloud
  Future<void> _onSyncToCloud(
    SyncToCloud event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // Check if user is authenticated
      final authToken = await authService.getAuthToken();
      if (authToken == null) {
        emit(const SyncError(message: 'Not authenticated'));
        return;
      }

      emit(const SyncInProgress(
        progress: 0.0,
        message: 'Preparing to upload tasks...',
      ));

      // Get all local tasks
      final localTasks = await taskRepository.getAllTasks();

      emit(const SyncInProgress(
        progress: 0.3,
        message: 'Uploading tasks...',
      ));

      // Upload tasks to cloud
      await cloudSyncService.uploadTasks(localTasks, authToken);

      emit(const SyncInProgress(
        progress: 1.0,
        message: 'Upload complete',
      ));

      // Emit success state
      emit(SyncComplete(
        syncTime: DateTime.now(),
        tasksSynced: localTasks.length,
      ));

      // Return to idle after a brief moment
      await Future.delayed(const Duration(seconds: 2));
      emit(SyncIdle(lastSyncTime: DateTime.now()));
    } catch (e) {
      emit(SyncError(
        message: 'Failed to sync to cloud',
        error: e,
      ));
      // Return to idle after error
      await Future.delayed(const Duration(seconds: 3));
      emit(const SyncIdle());
    }
  }

  /// Handle downloading tasks from the cloud
  Future<void> _onSyncFromCloud(
    SyncFromCloud event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // Check if user is authenticated
      final authToken = await authService.getAuthToken();
      if (authToken == null) {
        emit(const SyncError(message: 'Not authenticated'));
        return;
      }

      emit(const SyncInProgress(
        progress: 0.0,
        message: 'Downloading tasks...',
      ));

      // Download tasks from cloud
      final remoteTasks = await cloudSyncService.downloadTasks(authToken);

      emit(const SyncInProgress(
        progress: 0.5,
        message: 'Merging tasks...',
      ));

      // Get local tasks
      final localTasks = await taskRepository.getAllTasks();

      // Merge tasks (conflict resolution happens here)
      final mergedTasks = cloudSyncService.mergeTasks(localTasks, remoteTasks);

      emit(const SyncInProgress(
        progress: 0.8,
        message: 'Updating local storage...',
      ));

      // Update local storage with merged tasks
      // First, get the IDs of tasks that need to be added or updated
      final localTaskIds = localTasks.map((t) => t.id).toSet();
      final mergedTaskIds = mergedTasks.map((t) => t.id).toSet();

      // Delete tasks that are no longer in the merged set
      for (final localTask in localTasks) {
        if (!mergedTaskIds.contains(localTask.id)) {
          await taskRepository.deleteTask(localTask.id);
        }
      }

      // Add or update tasks from merged set
      for (final mergedTask in mergedTasks) {
        if (localTaskIds.contains(mergedTask.id)) {
          // Update existing task
          await taskRepository.updateTask(mergedTask);
        } else {
          // Create new task
          await taskRepository.createTask(mergedTask);
        }
      }

      emit(const SyncInProgress(
        progress: 1.0,
        message: 'Sync complete',
      ));

      // Emit success state
      emit(SyncComplete(
        syncTime: DateTime.now(),
        tasksSynced: mergedTasks.length,
      ));

      // Return to idle after a brief moment
      await Future.delayed(const Duration(seconds: 2));
      emit(SyncIdle(lastSyncTime: DateTime.now()));
    } catch (e) {
      emit(SyncError(
        message: 'Failed to sync from cloud',
        error: e,
      ));
      // Return to idle after error
      await Future.delayed(const Duration(seconds: 3));
      emit(const SyncIdle());
    }
  }

  /// Handle resolving a sync conflict
  Future<void> _onResolveSyncConflict(
    ResolveSyncConflict event,
    Emitter<SyncState> emit,
  ) async {
    // This is a placeholder for manual conflict resolution
    // In the current implementation, conflicts are automatically resolved
    // by keeping the version with the latest updatedAt timestamp
    // This event can be used for future manual conflict resolution UI
    emit(const SyncIdle());
  }
}
