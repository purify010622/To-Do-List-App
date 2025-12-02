/// Enum representing the type of sync operation
enum SyncOperation {
  create,
  update,
  delete,
}

/// SyncQueueItem model representing a queued sync operation
class SyncQueueItem {
  final String taskId;
  final SyncOperation operation;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SyncQueueItem({
    required this.taskId,
    required this.operation,
    DateTime? timestamp,
    required this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts this sync queue item to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'operation': operation.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  /// Creates a sync queue item from a JSON map
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      taskId: json['taskId'] as String,
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SyncQueueItem &&
        other.taskId == taskId &&
        other.operation == operation &&
        other.timestamp == timestamp &&
        _mapsEqual(other.data, data);
  }

  @override
  int get hashCode {
    return Object.hash(
      taskId,
      operation,
      timestamp,
      data.hashCode,
    );
  }

  @override
  String toString() {
    return 'SyncQueueItem(taskId: $taskId, operation: ${operation.name}, timestamp: $timestamp)';
  }

  /// Helper method to compare maps for equality
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}
