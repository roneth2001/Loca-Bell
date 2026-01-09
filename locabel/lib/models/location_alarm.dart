/// Model representing a location-based alarm
/// 
/// This model stores all information about a location alarm including
/// coordinates, trigger radius, ringtone, and activation status.
class LocationAlarm {
  /// Unique identifier for the alarm
  final String id;
  
  /// User-friendly name for the alarm (e.g., "Home", "Office", "Gym")
  final String name;
  
  /// GPS latitude coordinate
  final double latitude;
  
  /// GPS longitude coordinate
  final double longitude;
  
  /// Trigger radius in meters (default: 100m)
  /// The alarm will trigger when the user enters this radius
  final double radius;
  
  /// Selected ringtone identifier
  final String ringtone;
  
  /// Whether the alarm is currently active
  final bool isActive;
  
  /// Timestamp when the alarm was created
  final DateTime createdAt;
  
  /// Timestamp when the alarm was last updated (optional)
  final DateTime? updatedAt;
  
  /// Number of times this alarm has been triggered (optional)
  final int triggeredCount;

  /// Creates a new LocationAlarm instance
  LocationAlarm({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.ringtone = 'default',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.triggeredCount = 0,
  }) {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }
    
    // Validate radius
    if (radius < 50 || radius > 10000) {
      throw ArgumentError('Radius must be between 50 and 10000 meters');
    }
    
    // Validate name
    if (name.trim().isEmpty) {
      throw ArgumentError('Alarm name cannot be empty');
    }
  }

  /// Convert LocationAlarm to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'ringtone': ringtone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'triggeredCount': triggeredCount,
    };
  }

  /// Create LocationAlarm from JSON map
  factory LocationAlarm.fromJson(Map<String, dynamic> json) {
    return LocationAlarm(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      ringtone: json['ringtone'] as String? ?? 'default',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      triggeredCount: json['triggeredCount'] as int? ?? 0,
    );
  }

  /// Create a copy of this alarm with some fields updated
  LocationAlarm copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? ringtone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? triggeredCount,
  }) {
    return LocationAlarm(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      ringtone: ringtone ?? this.ringtone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      triggeredCount: triggeredCount ?? this.triggeredCount,
    );
  }

  /// Create a formatted location string
  String get locationString {
    return 'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
  }

  /// Create a short description of the alarm
  String get description {
    return '$name • ${radius.toInt()}m • $ringtone';
  }

  /// Check if the alarm is valid
  bool get isValid {
    return name.trim().isNotEmpty &&
           latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           radius >= 50 && radius <= 10000;
  }

  /// Get distance category for UI display
  String get radiusCategory {
    if (radius < 100) return 'Very Close';
    if (radius < 200) return 'Close';
    if (radius < 500) return 'Medium';
    if (radius < 1000) return 'Far';
    return 'Very Far';
  }

  @override
  String toString() {
    return 'LocationAlarm('
           'id: $id, '
           'name: $name, '
           'lat: $latitude, '
           'lng: $longitude, '
           'radius: ${radius.toInt()}m, '
           'active: $isActive'
           ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationAlarm && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension methods for LocationAlarm list operations
extension LocationAlarmListExtensions on List<LocationAlarm> {
  /// Get all active alarms
  List<LocationAlarm> get activeAlarms {
    return where((alarm) => alarm.isActive).toList();
  }

  /// Get all inactive alarms
  List<LocationAlarm> get inactiveAlarms {
    return where((alarm) => !alarm.isActive).toList();
  }

  /// Sort alarms by name
  List<LocationAlarm> sortedByName() {
    final sorted = List<LocationAlarm>.from(this);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Sort alarms by creation date (newest first)
  List<LocationAlarm> sortedByDate() {
    final sorted = List<LocationAlarm>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Sort alarms by triggered count (most triggered first)
  List<LocationAlarm> sortedByTriggered() {
    final sorted = List<LocationAlarm>.from(this);
    sorted.sort((a, b) => b.triggeredCount.compareTo(a.triggeredCount));
    return sorted;
  }

  /// Get alarm by ID
  LocationAlarm? findById(String id) {
    try {
      return firstWhere((alarm) => alarm.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search alarms by name
  List<LocationAlarm> search(String query) {
    if (query.trim().isEmpty) return this;
    
    final lowerQuery = query.toLowerCase();
    return where((alarm) {
      return alarm.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get total number of triggers across all alarms
  int get totalTriggers {
    return fold(0, (sum, alarm) => sum + alarm.triggeredCount);
  }

  /// Get most triggered alarm
  LocationAlarm? get mostTriggered {
    if (isEmpty) return null;
    return reduce((a, b) => 
      a.triggeredCount > b.triggeredCount ? a : b
    );
  }
}

/// Validation helper for alarm data
class AlarmValidator {
  /// Validate alarm name
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Alarm name is required';
    }
    if (name.length > 50) {
      return 'Name must be 50 characters or less';
    }
    return null;
  }

  /// Validate latitude
  static String? validateLatitude(double? latitude) {
    if (latitude == null) {
      return 'Latitude is required';
    }
    if (latitude < -90 || latitude > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  /// Validate longitude
  static String? validateLongitude(double? longitude) {
    if (longitude == null) {
      return 'Longitude is required';
    }
    if (longitude < -180 || longitude > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  /// Validate radius
  static String? validateRadius(double? radius) {
    if (radius == null) {
      return 'Radius is required';
    }
    if (radius < 50) {
      return 'Radius must be at least 50 meters';
    }
    if (radius > 10000) {
      return 'Radius cannot exceed 10,000 meters';
    }
    return null;
  }

  /// Validate entire alarm
  static Map<String, String> validateAlarm(LocationAlarm alarm) {
    final errors = <String, String>{};

    final nameError = validateName(alarm.name);
    if (nameError != null) errors['name'] = nameError;

    final latError = validateLatitude(alarm.latitude);
    if (latError != null) errors['latitude'] = latError;

    final lngError = validateLongitude(alarm.longitude);
    if (lngError != null) errors['longitude'] = lngError;

    final radiusError = validateRadius(alarm.radius);
    if (radiusError != null) errors['radius'] = radiusError;

    return errors;
  }
}