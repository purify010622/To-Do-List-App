import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/sync_queue_item.dart';
import '../models/task.dart';
import 'database_helper.dart';
import 'cloud_sync_service.dart';
import 'auth_service.dart';

/// Service for managing offline sync operations queue
class SyncQueueService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService cloudSyncService;
  final AuthService authService;

  static const String _tableName = 'sync_queue';

  SyncQueueService({
    required this.cloudSyncService,
    required this.authService,
  });

  /// Add an operation to the sync queue
  Future<void> enqueueOperation(SyncQueueItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      _itemToMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all queued operations, ordered by timestamp
  Future<List<SyncQueueItem>> getAllQueuedOperations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => _itemFromMap(map)).toList();
  }

  /// Remove an operation from the queue
  Future<void> dequeueOperation(String taskId, SyncOperation operation) async {
    final db = await _dbHelper.database;
    await db.delete(
      _tableName,
      where: 'taskId = ? AND operation = ?',
      whereArgs: [taskId, operation.name],
    );
  }

  /// Clear all operations from the queue
  Future<void> clearQueue() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName);
  }

  /// Process all queued operations when connectivity is restored
  /// Returns the number of operations successfully processed
  Future<int> processQueue() async {
    try {
      // Check if user is authenticated
      final authToken = await authService.getAuthToken();
      if (authToken == null) {
        // Not authenticated, cannot process queue
        return 0;
      }

      // Get all queued operations
      final queuedOperations = await getAllQueuedOperations();

      if (queuedOperations.isEmpty) {
        return 0;
      }

      int processedCount = 0;

      // Process operations in order
      for (final item in queuedOperations) {
        try {
          await _processOperation(item, authToken);
          await dequeueOperation(item.taskId, item.operation);
          processedCount++;
        } catch (e) {
          // If an operation fails, stop processing to maintain order
          // The failed operation will remain in the queue
          break;
        }
      }

      return processedCount;
    } catch (e) {
      throw Exception('Failed to process sync queue: $e');
    }
  }

  /// Process a single sync operation
  Future<void> _processOperation(
    SyncQueueItem item,
    String authToken,
  ) async {
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        // For create and update, we upload the task
        final task = Task.fromJson(item.data);
        await cloudSyncService.uploadTasks([task], authToken);
        break;

      case SyncOperation.delete:
        // For delete, we would need a delete endpoint on the backend
        // For now, we'll just remove it from the queue
        // In a full implementation, this would call a DELETE endpoint
        break;
    }
  }

  /// Convert a SyncQueueItem to a database map
  Map<String, dynamic> _itemToMap(SyncQueueItem item) {
    return {
      'taskId': item.taskId,
      'operation': item.operation.name,
      'timestamp': item.timestamp.millisecondsSinceEpoch,
      'data': _encodeData(item.data),
    };
  }

  /// Convert a database map to a SyncQueueItem
  SyncQueueItem _itemFromMap(Map<String, dynamic> map) {
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
}
