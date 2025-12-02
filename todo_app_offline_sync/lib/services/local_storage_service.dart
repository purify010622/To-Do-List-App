import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'database_helper.dart';

/// Local storage service implementing TaskRepository using SQLite
class LocalStorageService implements TaskRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<List<Task>> _tasksController =
      StreamController<List<Task>>.broadcast();
  bool _isDisposed = false;

  static const String _tableName = 'tasks';
  
  /// Create a LocalStorageService with optional custom database helper (for testing)
  LocalStorageService({DatabaseHelper? dbHelper}) 
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Get all tasks from local storage, sorted by priority (desc) and dueDate (asc)
  @override
  Future<List<Task>> getAllTasks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'priority DESC, dueDate ASC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  /// Get a specific task by ID
  @override
  Future<Task?> getTaskById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _taskFromMap(maps.first);
  }

  /// Create a new task in local storage
  @override
  Future<void> createTask(Task task) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      _taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Notify listeners
    _notifyListeners();
  }

  /// Update an existing task in local storage
  @override
  Future<void> updateTask(Task task) async {
    final db = await _dbHelper.database;
    await db.update(
      _tableName,
      _taskToMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Notify listeners
    _notifyListeners();
  }

  /// Delete a task from local storage
  @override
  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners
    _notifyListeners();
  }

  /// Watch tasks for reactive updates
  @override
  Stream<List<Task>> watchTasks() {
    // Emit initial data
    getAllTasks().then((tasks) {
      if (!_tasksController.isClosed) {
        _tasksController.add(tasks);
      }
    });

    return _tasksController.stream;
  }

  /// Notify all listeners of changes
  Future<void> _notifyListeners() async {
    if (!_isDisposed && !_tasksController.isClosed) {
      final tasks = await getAllTasks();
      _tasksController.add(tasks);
    }
  }

  /// Convert a Task object to a database map
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'priority': task.priority,
      'dueDate': task.dueDate?.millisecondsSinceEpoch,
      'completed': task.completed ? 1 : 0,
      'createdAt': task.createdAt.millisecondsSinceEpoch,
      'updatedAt': task.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert a database map to a Task object
  Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as int,
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Dispose resources
  void dispose() {
    _isDisposed = true;
    _tasksController.close();
  }
}
