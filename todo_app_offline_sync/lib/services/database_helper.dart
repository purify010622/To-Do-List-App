import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for managing SQLite database operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final String? _customDbName;

  DatabaseHelper._init() : _customDbName = null;
  
  /// Create a test instance with a custom database name
  DatabaseHelper.test(String dbName) : _customDbName = dbName;

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_customDbName ?? 'tasks.db');
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      singleInstance: false, // Allow multiple instances for testing
    );
  }

  /// Create the database schema
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority INTEGER NOT NULL,
        dueDate INTEGER,
        completed INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Add indexes for efficient sorting
    await db.execute('''
      CREATE INDEX idx_priority ON tasks(priority DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_dueDate ON tasks(dueDate ASC)
    ''');
    
    // Add composite index for common query pattern (priority + dueDate)
    await db.execute('''
      CREATE INDEX idx_priority_dueDate ON tasks(priority DESC, dueDate ASC)
    ''');
    
    // Add index for completed status for filtering
    await db.execute('''
      CREATE INDEX idx_completed ON tasks(completed)
    ''');

    // Create sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        taskId TEXT NOT NULL,
        operation TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        data TEXT NOT NULL,
        PRIMARY KEY (taskId, operation)
      )
    ''');

    // Add index for timestamp ordering
    await db.execute('''
      CREATE INDEX idx_sync_timestamp ON sync_queue(timestamp ASC)
    ''');
  }

  /// Handle database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sync_queue table in version 2
      await db.execute('''
        CREATE TABLE sync_queue (
          taskId TEXT NOT NULL,
          operation TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          data TEXT NOT NULL,
          PRIMARY KEY (taskId, operation)
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_sync_timestamp ON sync_queue(timestamp ASC)
      ''');
    }
    
    if (oldVersion < 3) {
      // Add performance indexes in version 3
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_priority_dueDate ON tasks(priority DESC, dueDate ASC)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_completed ON tasks(completed)
      ''');
    }
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Reset the database (useful for testing)
  Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');
    await deleteDatabase(path);
    _database = null;
  }
}
