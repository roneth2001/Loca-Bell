import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/location_alarm.dart';

/// Service for managing alarm audio playback and notifications
/// 
/// Handles ringtone playback, vibration, and alarm triggering events
class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer(); // Separate player for previews
  LocationAlarm? _currentAlarm;
  bool _isRinging = false;
  bool _isInitialized = false;
  bool _hasVibrator = false;

  /// Available ringtones
  final List<Map<String, String>> ringtones = [
    {'name': 'Default', 'value': 'default'},
    {'name': 'Classic Alarm', 'value': 'classic'},
    {'name': 'Digital Beep', 'value': 'digital'},
    {'name': 'Morning Bell', 'value': 'bell'},
    {'name': 'Gentle Wake', 'value': 'gentle'},
    {'name': 'Nature Sounds', 'value': 'nature'},
    {'name': 'Chime', 'value': 'chime'},
  ];

  /// Initialize the alarm service
  Future<void> init() async {
    if (_isInitialized) {
      print('AlarmService already initialized');
      return;
    }

    try {
      // Configure main audio player for continuous playback
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      
      // Configure preview player for one-time playback
      await _previewPlayer.setReleaseMode(ReleaseMode.stop);
      await _previewPlayer.setVolume(0.7); // Slightly lower volume for previews
      
      // Check vibration support
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      
      _isInitialized = true;
      print('✓ AlarmService initialized successfully');
      print('  - Vibration support: $_hasVibrator');
    } catch (e) {
      print('✗ Error initializing AlarmService: $e');
      rethrow;
    }
  }

  /// Trigger an alarm (start playing ringtone and vibration)
  Future<void> triggerAlarm(LocationAlarm alarm) async {
    if (_isRinging) {
      print('⚠ Alarm already ringing, ignoring trigger');
      return;
    }

    print('🔔 Triggering alarm: ${alarm.name}');
    
    _currentAlarm = alarm;
    _isRinging = true;

    try {
      // Start vibration first (instant feedback)
      await _startVibration();

      // Then play ringtone
      await _playRingtone(alarm.ringtone);
      
      print('✓ Alarm triggered successfully');
    } catch (e) {
      print('✗ Error triggering alarm: $e');
      // Continue with whatever started successfully
    }
  }

  /// Start continuous vibration pattern
  Future<void> _startVibration() async {
    if (!_hasVibrator) {
      print('⚠ Device does not support vibration');
      return;
    }

    try {
      // Vibration pattern: [wait, vibrate, wait, vibrate, ...]
      // Pattern in milliseconds: vibrate 1s, pause 0.5s, vibrate 1s, pause 0.5s, repeat
      await Vibration.vibrate(
        pattern: [0, 1000, 500, 1000],
        repeat: 0, // Repeat from index 0 (infinite loop)
      );
      print('✓ Vibration started');
    } catch (e) {
      print('✗ Error starting vibration: $e');
    }
  }

  /// Stop vibration
  Future<void> _stopVibration() async {
    if (!_hasVibrator) return;

    try {
      await Vibration.cancel();
      print('✓ Vibration stopped');
    } catch (e) {
      print('✗ Error stopping vibration: $e');
    }
  }

  /// Play the selected ringtone
  Future<void> _playRingtone(String ringtone) async {
    try {
      // Construct audio file path
      // Audio files should be in assets/sounds/ folder
      final String audioPath = 'sounds/$ringtone.mp3';
      
      print('▶ Playing ringtone: $audioPath');
      
      // Stop any existing playback
      await _audioPlayer.stop();
      
      // Play from assets (will loop due to ReleaseMode.loop)
      await _audioPlayer.play(AssetSource(audioPath));
      
      print('✓ Ringtone playing: $ringtone');
    } catch (e) {
      print('✗ Error playing ringtone: $e');
      print('⚠ Continuing with vibration only');
      // Don't rethrow - vibration still works
    }
  }

  /// Stop the current alarm
  Future<void> stopAlarm() async {
    if (!_isRinging) {
      print('⚠ No alarm currently ringing');
      return;
    }

    print('⏹ Stopping alarm: ${_currentAlarm?.name}');

    try {
      // Stop audio playback
      await _audioPlayer.stop();
      
      // Stop vibration
      await _stopVibration();
      
      _isRinging = false;
      _currentAlarm = null;
      
      print('✓ Alarm stopped successfully');
    } catch (e) {
      print('✗ Error stopping alarm: $e');
      // Force reset state even on error
      _isRinging = false;
      _currentAlarm = null;
    }
  }

  /// Snooze the current alarm
  Future<void> snoozeAlarm(
    LocationAlarm alarm, {
    Duration snoozeDuration = const Duration(minutes: 5),
  }) async {
    print('⏰ Snoozing alarm for ${snoozeDuration.inMinutes} minutes');
    
    final snoozedAlarm = _currentAlarm;
    
    // Stop the alarm
    await stopAlarm();
    
    print('✓ Alarm snoozed: ${snoozedAlarm?.name}');
    
    // Note: Re-triggering after snooze duration is handled by LocationService
    // which will check proximity again after the snooze period
  }

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    // Clamp volume to valid range
    final clampedVolume = volume.clamp(0.0, 1.0);
    
    if (volume != clampedVolume) {
      print('⚠ Volume clamped from $volume to $clampedVolume');
    }
    
    try {
      await _audioPlayer.setVolume(clampedVolume);
      print('✓ Volume set to: $clampedVolume');
    } catch (e) {
      print('✗ Error setting volume: $e');
    }
  }

  /// Preview a ringtone (for selection screen)
  Future<void> previewRingtone(
    String ringtone, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    try {
      final audioPath = 'sounds/$ringtone.mp3';
      
      print('👂 Previewing ringtone: $ringtone');
      
      // Stop any current preview
      await _previewPlayer.stop();
      
      // Play preview (will auto-stop due to ReleaseMode.stop)
      await _previewPlayer.play(AssetSource(audioPath));
      
      // Auto-stop after duration
      Future.delayed(duration, () async {
        try {
          await _previewPlayer.stop();
          print('✓ Preview stopped');
        } catch (e) {
          print('✗ Error stopping preview: $e');
        }
      });
    } catch (e) {
      print('✗ Error previewing ringtone: $e');
      // Preview failure is not critical - just log it
    }
  }

  /// Stop ringtone preview immediately
  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
      print('✓ Preview stopped manually');
    } catch (e) {
      print('✗ Error stopping preview: $e');
    }
  }

  /// Get the display name for a ringtone value
  String getRingtoneName(String value) {
    final ringtone = ringtones.firstWhere(
      (r) => r['value'] == value,
      orElse: () => ringtones[0], // Default to first ringtone
    );
    return ringtone['name']!;
  }

  /// Get ringtone value from display name
  String? getRingtoneValue(String name) {
    try {
      final ringtone = ringtones.firstWhere(
        (r) => r['name'] == name,
      );
      return ringtone['value'];
    } catch (e) {
      return null; // Name not found
    }
  }

  /// Check if a ringtone value is valid
  bool isValidRingtone(String ringtone) {
    return ringtones.any((r) => r['value'] == ringtone);
  }

  /// Get list of all ringtone names
  List<String> getRingtoneNames() {
    return ringtones.map((r) => r['name']!).toList();
  }

  /// Get list of all ringtone values
  List<String> getRingtoneValues() {
    return ringtones.map((r) => r['value']!).toList();
  }

  /// Get currently ringing alarm (if any)
  LocationAlarm? get currentAlarm => _currentAlarm;

  /// Check if an alarm is currently ringing
  bool get isRinging => _isRinging;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if device has vibration support
  bool get hasVibrator => _hasVibrator;

  /// Clean up resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      await _previewPlayer.dispose();
      await _stopVibration();
      _isInitialized = false;
      print('✓ AlarmService disposed');
    } catch (e) {
      print('✗ Error disposing AlarmService: $e');
    }
  }
}