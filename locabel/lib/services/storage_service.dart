import '../models/location_alarm.dart';
import '../database/database_helper.dart';

/// Storage service using SQLite for offline-first data persistence
/// 
/// This service provides a clean interface to the underlying SQLite database
/// for all alarm data operations. All data is stored locally on the device.
class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) {
      print('StorageService already initialized');
      return;
    }

    try {
      // Initialize database
      await _db.database;
      
      _isInitialized = true;
      print('StorageService initialized with SQLite');
    } catch (e) {
      print('Error initializing StorageService: $e');
      rethrow;
    }
  }

  // ========== ALARM OPERATIONS ==========

  /// Get all alarms from database
  Future<List<LocationAlarm>> getAlarms() async {
    try {
      return await _db.getAllAlarms();
    } catch (e) {
      print('Error getting alarms: $e');
      return [];
    }
  }

  /// Get only active alarms
  Future<List<LocationAlarm>> getActiveAlarms() async {
    try {
      return await _db.getActiveAlarms();
    } catch (e) {
      print('Error getting active alarms: $e');
      return [];
    }
  }

  /// Get alarm by ID
  Future<LocationAlarm?> getAlarmById(String id) async {
    try {
      return await _db.getAlarmById(id);
    } catch (e) {
      print('Error getting alarm by ID: $e');
      return null;
    }
  }

  /// Add new alarm to database
  Future<void> addAlarm(LocationAlarm alarm) async {
    try {
      await _db.insertAlarm(alarm);
      print('Alarm added: ${alarm.name}');
    } catch (e) {
      print('Error adding alarm: $e');
      rethrow;
    }
  }

  /// Update existing alarm in database
  Future<void> updateAlarm(LocationAlarm updatedAlarm) async {
    try {
      await _db.updateAlarm(updatedAlarm);
      print('Alarm updated: ${updatedAlarm.name}');
    } catch (e) {
      print('Error updating alarm: $e');
      rethrow;
    }
  }

  /// Delete alarm from database
  Future<void> deleteAlarm(String id) async {
    try {
      await _db.deleteAlarm(id);
      print('Alarm deleted: $id');
    } catch (e) {
      print('Error deleting alarm: $e');
      rethrow;
    }
  }

  /// Delete all alarms (use with caution!)
  Future<void> clearAll() async {
    try {
      await _db.deleteAllAlarms();
      print('All alarms deleted');
    } catch (e) {
      print('Error clearing all alarms: $e');
      rethrow;
    }
  }

  /// Save multiple alarms at once (for bulk operations)
  Future<void> saveAlarms(List<LocationAlarm> alarms) async {
    try {
      for (final alarm in alarms) {
        await _db.insertAlarm(alarm);
      }
      print('${alarms.length} alarms saved');
    } catch (e) {
      print('Error saving alarms: $e');
      rethrow;
    }
  }

  // ========== HISTORY OPERATIONS ==========

  /// Record when an alarm is triggered
  Future<void> recordAlarmTrigger({
    required String alarmId,
    required String alarmName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.insertHistory(
        alarmId: alarmId,
        alarmName: alarmName,
        latitude: latitude,
        longitude: longitude,
      );
      await _db.incrementTriggeredCount(alarmId);
      print('Alarm trigger recorded: $alarmName');
    } catch (e) {
      print('Error recording alarm trigger: $e');
    }
  }

  /// Get all alarm history
  Future<List<Map<String, dynamic>>> getAlarmHistory() async {
    try {
      return await _db.getAllHistory();
    } catch (e) {
      print('Error getting alarm history: $e');
      return [];
    }
  }

  /// Get history for specific alarm
  Future<List<Map<String, dynamic>>> getHistoryForAlarm(String alarmId) async {
    try {
      return await _db.getHistoryForAlarm(alarmId);
    } catch (e) {
      print('Error getting history for alarm: $e');
      return [];
    }
  }

  /// Mark history record as dismissed
  Future<void> markHistoryDismissed(int historyId) async {
    try {
      await _db.markHistoryDismissed(historyId);
    } catch (e) {
      print('Error marking history dismissed: $e');
    }
  }

  /// Clean up old history records (older than specified days)
  Future<void> cleanupOldHistory({int daysToKeep = 30}) async {
    try {
      final deletedCount = await _db.deleteOldHistory(daysToKeep);
      print('Cleaned up $deletedCount old history records');
    } catch (e) {
      print('Error cleaning up old history: $e');
    }
  }

  // ========== SETTINGS OPERATIONS ==========

  /// Save app setting
  Future<void> saveSetting(String key, String value) async {
    try {
      await _db.saveSetting(key, value);
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  /// Get app setting
  Future<String?> getSetting(String key) async {
    try {
      return await _db.getSetting(key);
    } catch (e) {
      print('Error getting setting: $e');
      return null;
    }
  }

  /// Delete app setting
  Future<void> deleteSetting(String key) async {
    try {
      await _db.deleteSetting(key);
    } catch (e) {
      print('Error deleting setting: $e');
    }
  }

  // ========== STATISTICS ==========

  /// Get total number of alarms
  Future<int> getAlarmsCount() async {
    try {
      return await _db.getAlarmsCount();
    } catch (e) {
      print('Error getting alarms count: $e');
      return 0;
    }
  }

  /// Get number of active alarms
  Future<int> getActiveAlarmsCount() async {
    try {
      return await _db.getActiveAlarmsCount();
    } catch (e) {
      print('Error getting active alarms count: $e');
      return 0;
    }
  }

  /// Get total number of times alarms have been triggered
  Future<int> getTotalTriggersCount() async {
    try {
      return await _db.getTotalTriggersCount();
    } catch (e) {
      print('Error getting total triggers count: $e');
      return 0;
    }
  }

  /// Get the most frequently triggered alarm
  Future<LocationAlarm?> getMostTriggeredAlarm() async {
    try {
      final alarmMap = await _db.getMostTriggeredAlarm();
      if (alarmMap == null) return null;
      
      return LocationAlarm(
        id: alarmMap['id'],
        name: alarmMap['name'],
        latitude: alarmMap['latitude'],
        longitude: alarmMap['longitude'],
        radius: alarmMap['radius'],
        ringtone: alarmMap['ringtone'],
        isActive: alarmMap['is_active'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(alarmMap['created_at']),
        triggeredCount: alarmMap['triggered_count'] ?? 0,
      );
    } catch (e) {
      print('Error getting most triggered alarm: $e');
      return null;
    }
  }

  // ========== BACKUP & RESTORE ==========

  /// Get database file path for backup
  Future<String> getDatabasePath() async {
    try {
      return await _db.exportDatabase();
    } catch (e) {
      print('Error getting database path: $e');
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    try {
      await _db.closeDatabase();
      _isInitialized = false;
      print('StorageService closed');
    } catch (e) {
      print('Error closing storage service: $e');
    }
  }

  /// Delete all data and reset database (use with extreme caution!)
  Future<void> resetDatabase() async {
    try {
      await _db.deleteDatabase();
      await init(); // Reinitialize after deletion
      print('Database reset completed');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }

  // ========== HELPER METHODS ==========

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Export all alarms as JSON list (for backup)
  Future<List<Map<String, dynamic>>> exportAlarmsAsJson() async {
    try {
      final alarms = await getAlarms();
      return alarms.map((alarm) => alarm.toJson()).toList();
    } catch (e) {
      print('Error exporting alarms: $e');
      return [];
    }
  }

  /// Import alarms from JSON list (for restore)
  Future<void> importAlarmsFromJson(List<Map<String, dynamic>> jsonList) async {
    try {
      final alarms = jsonList.map((json) => LocationAlarm.fromJson(json)).toList();
      await saveAlarms(alarms);
      print('Imported ${alarms.length} alarms');
    } catch (e) {
      print('Error importing alarms: $e');
      rethrow;
    }
  }

  /// Search alarms by name
  Future<List<LocationAlarm>> searchAlarms(String query) async {
    try {
      final alarms = await getAlarms();
      if (query.trim().isEmpty) return alarms;
      
      final lowerQuery = query.toLowerCase();
      return alarms.where((alarm) {
        return alarm.name.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching alarms: $e');
      return [];
    }
  }
}