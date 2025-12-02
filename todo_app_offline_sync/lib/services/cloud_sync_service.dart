import 'package:dio/dio.dart';
import '../models/task.dart';
import '../config/app_config.dart';

/// Service for synchronizing tasks with the cloud backend
class CloudSyncService {
  final Dio _dio;
  final String baseUrl;

  CloudSyncService({
    Dio? dio,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _dio = dio ?? Dio(
          BaseOptions(
            connectTimeout: AppConfig.apiTimeout,
            receiveTimeout: AppConfig.apiTimeout,
            sendTimeout: AppConfig.apiTimeout,
          ),
        );

  /// Upload tasks to the backend
  /// Returns the list of tasks that were successfully uploaded
  Future<List<Task>> uploadTasks(
    List<Task> tasks,
    String authToken,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/tasks/sync',
        data: {
          'tasks': tasks.map((task) => task.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> tasksJson = response.data['tasks'] as List<dynamic>;
        return tasksJson
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to upload tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during upload: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload tasks: $e');
    }
  }

  /// Download tasks from the backend
  /// Returns the list of tasks from the cloud
  Future<List<Task>> downloadTasks(String authToken) async {
    try {
      final response = await _dio.get(
        '$baseUrl/tasks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = response.data['tasks'] as List<dynamic>;
        return tasksJson
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to download tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during download: ${e.message}');
    } catch (e) {
      throw Exception('Failed to download tasks: $e');
    }
  }

  /// Merge local and remote tasks, resolving conflicts
  /// Conflict resolution: keep the version with the latest updatedAt timestamp
  /// Duplicate detection: tasks with the same ID are considered duplicates
  /// Returns the merged list of tasks without duplicates
  List<Task> mergeTasks(List<Task> localTasks, List<Task> remoteTasks) {
    // Create a map to track tasks by ID
    final Map<String, Task> mergedMap = {};

    // Add all local tasks to the map
    for (final task in localTasks) {
      mergedMap[task.id] = task;
    }

    // Process remote tasks
    for (final remoteTask in remoteTasks) {
      final existingTask = mergedMap[remoteTask.id];

      if (existingTask == null) {
        // No conflict - add the remote task
        mergedMap[remoteTask.id] = remoteTask;
      } else {
        // Conflict detected - keep the version with the latest updatedAt
        if (remoteTask.updatedAt.isAfter(existingTask.updatedAt)) {
          mergedMap[remoteTask.id] = remoteTask;
        }
        // If local is newer or equal, keep the existing (local) version
      }
    }

    // Return the merged list
    return mergedMap.values.toList();
  }
}
