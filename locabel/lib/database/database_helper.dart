import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_alarm.dart';

/// Database helper for SQLite operations
/// 
/// Manages the local SQLite database for storing alarms, history, and settings.
/// This provides offline-first data persistence with no internet required.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  // Database configuration
  static const String _databaseName = 'location_alarm.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableAlarms = 'alarms';
  static const String tableHistory = 'alarm_history';
  static const String tableSettings = 'user_settings';

  // Alarms table columns
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnRadius = 'radius';
  static const String columnRingtone = 'ringtone';
  static const String columnIsActive = 'is_active';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnTriggeredCount = 'triggered_count';

  // History table columns
  static const String columnHistoryId = 'history_id';
  static const String columnAlarmId = 'alarm_id';
  static const String columnAlarmName = 'alarm_name';
  static const String columnTriggeredAt = 'triggered_at';
  static const String columnDismissed = 'dismissed';
  static const String columnDismissedAt = 'dismissed_at';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    print('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        print('Database opened successfully');
      },
    );
  }

  /// Create tables when database is first created
  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');

    // Create alarms table
    await db.execute('''
      CREATE TABLE $tableAlarms (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnRadius REAL NOT NULL DEFAULT 100.0,
        $columnRingtone TEXT NOT NULL DEFAULT 'default',
        $columnIsActive INTEGER NOT NULL DEFAULT 1,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnTriggeredCount INTEGER DEFAULT 0
      )
    ''');

    print('✓ Alarms table created');

    // Create alarm history table
    await db.execute('''
      CREATE TABLE $tableHistory (
        $columnHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnAlarmId TEXT NOT NULL,
        $columnAlarmName TEXT NOT NULL,
        $columnTriggeredAt INTEGER NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnDismissed INTEGER NOT NULL DEFAULT 0,
        $columnDismissedAt INTEGER,
        FOREIGN KEY ($columnAlarmId) REFERENCES $tableAlarms($columnId) ON DELETE CASCADE
      )
    ''');

    print('✓ History table created');

    // Create user settings table
    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    print('✓ Settings table created');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_alarms_active ON $tableAlarms($columnIsActive)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_alarm ON $tableHistory($columnAlarmId)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_date ON $tableHistory($columnTriggeredAt)
    ''');

    print('✓ Indexes created');
    print('Database setup completed successfully');
  }

  /// Handle database upgrades (future versions)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from v$oldVersion to v$newVersion');

    // Example: Handle schema changes in future versions
    if (oldVersion < 2) {
      // await db.execute('ALTER TABLE $tableAlarms ADD COLUMN new_column TEXT');
    }

    // Add more version migrations as needed
  }

  // ========== ALARM OPERATIONS ==========

  /// Insert a new alarm into the database
  Future<int> insertAlarm(LocationAlarm alarm) async {
    try {
      final db = await database;
      final result = await db.insert(
        tableAlarms,
        _alarmToMap(alarm),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✓ Alarm inserted: ${alarm.name} (ID: ${alarm.id})');
      return result;
    } catch (e) {
      print('✗ Error inserting alarm: $e');
      rethrow;
    }
  }

  /// Get all alarms from the database
  Future<List<LocationAlarm>> getAllAlarms() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableAlarms,
        orderBy: '$columnCreatedAt DESC',
      );
      
      final alarms = maps.map((map) => _alarmFromMap(map)).toList();
      print('Retrieved ${alarms.length} alarms from database');
      return alarms;
    } catch (e) {
      print('✗ Error getting alarms: $e');
      return [];
    }
  }

  /// Get a specific alarm by ID
  Future<LocationAlarm?> getAlarmById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableAlarms,
        where: '$columnId = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        print('Alarm not found: $id');
        return null;
      }
      
      return _alarmFromMap(maps.first);
    } catch (e) {
      print('✗ Error getting alarm by ID: $e');
      return null;
    }
  }

  /// Get only active alarms
  Future<List<LocationAlarm>> getActiveAlarms() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableAlarms,
        where: '$columnIsActive = ?',
        whereArgs: [1],
        orderBy: '$columnCreatedAt DESC',
      );
      
      final alarms = maps.map((map) => _alarmFromMap(map)).toList();
      print('Retrieved ${alarms.length} active alarms');
      return alarms;
    } catch (e) {
      print('✗ Error getting active alarms: $e');
      return [];
    }
  }

  /// Update an existing alarm
  Future<int> updateAlarm(LocationAlarm alarm) async {
    try {
      final db = await database;
      final updatedAlarm = alarm.copyWith(
        updatedAt: DateTime.now(),
      );
      
      final result = await db.update(
        tableAlarms,
        _alarmToMap(updatedAlarm),
        where: '$columnId = ?',
        whereArgs: [alarm.id],
      );
      
      print('✓ Alarm updated: ${alarm.name}');
      return result;
    } catch (e) {
      print('✗ Error updating alarm: $e');
      rethrow;
    }
  }

  /// Delete an alarm
  Future<int> deleteAlarm(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        tableAlarms,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      print('✓ Alarm deleted: $id');
      return result;
    } catch (e) {
      print('✗ Error deleting alarm: $e');
      rethrow;
    }
  }

  /// Delete all alarms
  Future<int> deleteAllAlarms() async {
    try {
      final db = await database;
      final result = await db.delete(tableAlarms);
      print('✓ All alarms deleted');
      return result;
    } catch (e) {
      print('✗ Error deleting all alarms: $e');
      rethrow;
    }
  }

  /// Increment the triggered count for an alarm
  Future<void> incrementTriggeredCount(String alarmId) async {
    try {
      final db = await database;
      await db.rawUpdate('''
        UPDATE $tableAlarms 
        SET $columnTriggeredCount = $columnTriggeredCount + 1 
        WHERE $columnId = ?
      ''', [alarmId]);
      
      print('✓ Incremented trigger count for alarm: $alarmId');
    } catch (e) {
      print('✗ Error incrementing triggered count: $e');
    }
  }

  // ========== HISTORY OPERATIONS ==========

  /// Insert a history record
  Future<int> insertHistory({
    required String alarmId,
    required String alarmName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final db = await database;
      final result = await db.insert(tableHistory, {
        columnAlarmId: alarmId,
        columnAlarmName: alarmName,
        columnTriggeredAt: DateTime.now().millisecondsSinceEpoch,
        columnLatitude: latitude,
        columnLongitude: longitude,
        columnDismissed: 0,
      });
      
      print('✓ History record inserted for: $alarmName');
      return result;
    } catch (e) {
      print('✗ Error inserting history: $e');
      rethrow;
    }
  }

  /// Get all history records
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    try {
      final db = await database;
      final history = await db.query(
        tableHistory,
        orderBy: '$columnTriggeredAt DESC',
      );
      
      print('Retrieved ${history.length} history records');
      return history;
    } catch (e) {
      print('✗ Error getting history: $e');
      return [];
    }
  }

  /// Get history for a specific alarm
  Future<List<Map<String, dynamic>>> getHistoryForAlarm(String alarmId) async {
    try {
      final db = await database;
      final history = await db.query(
        tableHistory,
        where: '$columnAlarmId = ?',
        whereArgs: [alarmId],
        orderBy: '$columnTriggeredAt DESC',
      );
      
      print('Retrieved ${history.length} history records for alarm: $alarmId');
      return history;
    } catch (e) {
      print('✗ Error getting alarm history: $e');
      return [];
    }
  }

  /// Mark a history record as dismissed
  Future<int> markHistoryDismissed(int historyId) async {
    try {
      final db = await database;
      final result = await db.update(
        tableHistory,
        {
          columnDismissed: 1,
          columnDismissedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$columnHistoryId = ?',
        whereArgs: [historyId],
      );
      
      print('✓ History marked as dismissed: $historyId');
      return result;
    } catch (e) {
      print('✗ Error marking history dismissed: $e');
      rethrow;
    }
  }

  /// Delete old history records (older than specified days)
  Future<int> deleteOldHistory(int daysOld) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final result = await db.delete(
        tableHistory,
        where: '$columnTriggeredAt < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );
      
      print('✓ Deleted $result old history records (older than $daysOld days)');
      return result;
    } catch (e) {
      print('✗ Error deleting old history: $e');
      return 0;
    }
  }

  // ========== SETTINGS OPERATIONS ==========

  /// Save a setting
  Future<int> saveSetting(String key, String value) async {
    try {
      final db = await database;
      final result = await db.insert(
        tableSettings,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✓ Setting saved: $key');
      return result;
    } catch (e) {
      print('✗ Error saving setting: $e');
      rethrow;
    }
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableSettings,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      
      return maps.first['value'] as String;
    } catch (e) {
      print('✗ Error getting setting: $e');
      return null;
    }
  }

  /// Delete a setting
  Future<int> deleteSetting(String key) async {
    try {
      final db = await database;
      final result = await db.delete(
        tableSettings,
        where: 'key = ?',
        whereArgs: [key],
      );
      
      print('✓ Setting deleted: $key');
      return result;
    } catch (e) {
      print('✗ Error deleting setting: $e');
      return 0;
    }
  }

  // ========== STATISTICS ==========

  /// Get total alarms count
  Future<int> getAlarmsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableAlarms'
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('✗ Error getting alarms count: $e');
      return 0;
    }
  }

  /// Get active alarms count
  Future<int> getActiveAlarmsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableAlarms WHERE $columnIsActive = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('✗ Error getting active alarms count: $e');
      return 0;
    }
  }

  /// Get total triggers count
  Future<int> getTotalTriggersCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableHistory',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('✗ Error getting total triggers count: $e');
      return 0;
    }
  }

  /// Get the most triggered alarm
  Future<Map<String, dynamic>?> getMostTriggeredAlarm() async {
    try {
      final db = await database;
      final result = await db.query(
        tableAlarms,
        orderBy: '$columnTriggeredCount DESC',
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      print('✗ Error getting most triggered alarm: $e');
      return null;
    }
  }

  // ========== UTILITY METHODS ==========

  /// Convert LocationAlarm to database map
  Map<String, dynamic> _alarmToMap(LocationAlarm alarm) {
    return {
      columnId: alarm.id,
      columnName: alarm.name,
      columnLatitude: alarm.latitude,
      columnLongitude: alarm.longitude,
      columnRadius: alarm.radius,
      columnRingtone: alarm.ringtone,
      columnIsActive: alarm.isActive ? 1 : 0,
      columnCreatedAt: alarm.createdAt.millisecondsSinceEpoch,
      columnUpdatedAt: (alarm.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      columnTriggeredCount: alarm.triggeredCount,
    };
  }

  /// Convert database map to LocationAlarm
  LocationAlarm _alarmFromMap(Map<String, dynamic> map) {
    return LocationAlarm(
      id: map[columnId] as String,
      name: map[columnName] as String,
      latitude: map[columnLatitude] as double,
      longitude: map[columnLongitude] as double,
      radius: map[columnRadius] as double,
      ringtone: map[columnRingtone] as String,
      isActive: map[columnIsActive] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[columnCreatedAt] as int),
      updatedAt: map[columnUpdatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[columnUpdatedAt] as int)
          : null,
      triggeredCount: map[columnTriggeredCount] as int? ?? 0,
    );
  }

  /// Export database file path (for backup)
  Future<String> exportDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    return path;
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    print('Database closed');
  }

  /// Delete the entire database (use with extreme caution!)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('Database deleted');
  }
}