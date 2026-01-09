import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_alarm.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

/// Location service for GPS tracking and alarm triggering
/// 
/// Monitors user's location continuously and triggers alarms when
/// the user enters the specified radius of any active alarm.
class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  bool _isMonitoring = false;
  bool _isInitialized = false;
  
  // Track which alarms have been triggered to prevent duplicate alerts
  final Set<String> _triggeredAlarms = {};

  /// Initialize the location service
  Future<void> init() async {
    if (_isInitialized) {
      print('LocationService already initialized');
      return;
    }

    try {
      // Check location permissions
      await _checkAndRequestPermissions();
      
      _isInitialized = true;
      print('LocationService initialized successfully');
    } catch (e) {
      print('Error initializing LocationService: $e');
      rethrow;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return false;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    print('Location permissions granted');
    return true;
  }

  /// Start continuous location monitoring
  Future<void> startLocationMonitoring() async {
    if (_isMonitoring) {
      print('Location monitoring already active');
      return;
    }

    try {
      // Check permissions first
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        print('Cannot start monitoring: No location permission');
        return;
      }

      // Configure location settings
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      // Start listening to position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          print('Location stream error: $error');
        },
      );

      _isMonitoring = true;
      print('Location monitoring started');
    } catch (e) {
      print('Error starting location monitoring: $e');
      rethrow;
    }
  }

  /// Stop location monitoring
  void stopLocationMonitoring() {
    if (!_isMonitoring) {
      print('Location monitoring not active');
      return;
    }

    try {
      _positionSubscription?.cancel();
      _positionSubscription = null;
      _isMonitoring = false;
      _triggeredAlarms.clear();
      
      print('Location monitoring stopped');
    } catch (e) {
      print('Error stopping location monitoring: $e');
    }
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    _currentPosition = position;
    
    print('Location update: ${position.latitude}, ${position.longitude}');

    try {
      // Get all active alarms from database
      final activeAlarms = await StorageService.instance.getActiveAlarms();
      
      if (activeAlarms.isEmpty) {
        print('No active alarms to check');
        return;
      }

      // Check each active alarm
      for (final alarm in activeAlarms) {
        await _checkAlarmProximity(alarm, position);
      }
    } catch (e) {
      print('Error checking alarms: $e');
    }
  }

  /// Check if user is within alarm radius
  Future<void> _checkAlarmProximity(
    LocationAlarm alarm,
    Position position,
  ) async {
    try {
      // Calculate distance between current position and alarm location
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        alarm.latitude,
        alarm.longitude,
      );

      print('Distance to ${alarm.name}: ${distance.toStringAsFixed(1)}m (radius: ${alarm.radius}m)');

      // Check if within radius
      if (distance <= alarm.radius) {
        // Check if alarm hasn't been triggered yet
        if (!_triggeredAlarms.contains(alarm.id)) {
          print('ALARM TRIGGERED: ${alarm.name}');
          await _triggerAlarm(alarm, position);
        }
      } else {
        // User left the radius, reset trigger state
        if (_triggeredAlarms.contains(alarm.id)) {
          _triggeredAlarms.remove(alarm.id);
          print('User left radius of: ${alarm.name}');
        }
      }
    } catch (e) {
      print('Error checking alarm proximity: $e');
    }
  }

  /// Trigger an alarm
  Future<void> _triggerAlarm(LocationAlarm alarm, Position position) async {
    try {
      // Mark as triggered
      _triggeredAlarms.add(alarm.id);

      // Record in history
      await StorageService.instance.recordAlarmTrigger(
        alarmId: alarm.id,
        alarmName: alarm.name,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Trigger alarm sound and vibration
      await AlarmService.instance.triggerAlarm(alarm);

      print('Alarm triggered successfully: ${alarm.name}');
    } catch (e) {
      print('Error triggering alarm: $e');
    }
  }

  /// Get current position (one-time request)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        print('Cannot get position: No location permission');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open app settings to enable location
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Reset triggered alarms (useful after dismissing an alarm)
  void resetTriggeredAlarm(String alarmId) {
    _triggeredAlarms.remove(alarmId);
    print('Reset triggered state for alarm: $alarmId');
  }

  /// Reset all triggered alarms
  void resetAllTriggeredAlarms() {
    _triggeredAlarms.clear();
    print('Reset all triggered alarms');
  }

  /// Get current position (cached)
  Position? get currentPosition => _currentPosition;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get list of currently triggered alarm IDs
  Set<String> get triggeredAlarmIds => Set.from(_triggeredAlarms);

  /// Dispose resources
  void dispose() {
    stopLocationMonitoring();
    print('LocationService disposed');
  }
}

/// Location permission status helper
class LocationPermissionStatus {
  static String getStatusText(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted (while in use)';
      case LocationPermission.always:
        return 'Location permission granted (always)';
      default:
        return 'Unknown permission status';
    }
  }

  static bool isGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
}

/// Location accuracy helper
class LocationAccuracyHelper {
  static String getAccuracyText(Position position) {
    if (position.accuracy < 10) {
      return 'Excellent (${position.accuracy.toStringAsFixed(1)}m)';
    } else if (position.accuracy < 50) {
      return 'Good (${position.accuracy.toStringAsFixed(1)}m)';
    } else if (position.accuracy < 100) {
      return 'Fair (${position.accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (${position.accuracy.toStringAsFixed(1)}m)';
    }
  }

  static bool isAccurate(Position position, {double threshold = 50}) {
    return position.accuracy <= threshold;
  }
}