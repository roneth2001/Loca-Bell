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
  LocationAlarm? _currentAlarm;
  bool _isRinging = false;
  bool _isInitialized = false;

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
    if (_isInitialized) return;

    try {
      // Set audio player to loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Set initial volume
      await _audioPlayer.setVolume(1.0);
      
      _isInitialized = true;
      print('AlarmService initialized successfully');
    } catch (e) {
      print('Error initializing AlarmService: $e');
    }
  }

  /// Trigger an alarm (start playing ringtone and vibration)
  Future<void> triggerAlarm(LocationAlarm alarm) async {
    if (_isRinging) {
      print('Alarm already ringing, ignoring trigger');
      return;
    }

    print('Triggering alarm: ${alarm.name}');
    
    _currentAlarm = alarm;
    _isRinging = true;

    // Start vibration
    await _startVibration();

    // Play ringtone
    await _playRingtone(alarm.ringtone);
  }

  /// Start continuous vibration pattern
  Future<void> _startVibration() async {
    try {
      // Check if device has vibrator
      final hasVibrator = await Vibration.hasVibrator();
      
      if (hasVibrator == true) {
        // Vibration pattern: [wait, vibrate, wait, vibrate, ...]
        // Pattern in milliseconds
        await Vibration.vibrate(
          pattern: [0, 1000, 500, 1000], // Vibrate for 1s, pause 0.5s, repeat
          repeat: 0, // Repeat from index 0
        );
        print('Vibration started');
      } else {
        print('Device does not support vibration');
      }
    } catch (e) {
      print('Error starting vibration: $e');
    }
  }

  /// Stop vibration
  Future<void> _stopVibration() async {
    try {
      await Vibration.cancel();
      print('Vibration stopped');
    } catch (e) {
      print('Error stopping vibration: $e');
    }
  }

  /// Play the selected ringtone
  Future<void> _playRingtone(String ringtone) async {
    try {
      // Construct audio file path
      // Audio files should be in assets/sounds/ folder
      final String audioPath = 'sounds/$ringtone.mp3';
      
      print('Attempting to play ringtone: $audioPath');
      
      // Try to play the audio from assets
      await _audioPlayer.play(AssetSource(audioPath));
      
      print('Ringtone playing: $ringtone');
    } catch (e) {
      print('Error playing ringtone: $e');
      
      // Fallback: Continue with vibration only
      print('Continuing with vibration only');
    }
  }

  /// Stop the current alarm
  Future<void> stopAlarm() async {
    if (!_isRinging) return;

    print('Stopping alarm: ${_currentAlarm?.name}');

    try {
      // Stop audio
      await _audioPlayer.stop();
      
      // Stop vibration
      await _stopVibration();
      
      _isRinging = false;
      _currentAlarm = null;
      
      print('Alarm stopped successfully');
    } catch (e) {
      print('Error stopping alarm: $e');
      _isRinging = false;
      _currentAlarm = null;
    }
  }

  /// Snooze the current alarm
  Future<void> snoozeAlarm({Duration snoozeDuration = const Duration(minutes: 5)}) async {
    print('Snoozing alarm for ${snoozeDuration.inMinutes} minutes');
    
    final snoozeAlarm = _currentAlarm;
    await stopAlarm();
    
    print('Alarm snoozed: ${snoozeAlarm?.name}');
  }

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      print('Invalid volume level: $volume. Must be between 0.0 and 1.0');
      return;
    }
    
    try {
      await _audioPlayer.setVolume(volume);
      print('Volume set to: $volume');
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Preview a ringtone (for selection screen)
  Future<void> previewRingtone(String ringtone, {Duration duration = const Duration(seconds: 3)}) async {
    try {
      final audioPath = 'sounds/$ringtone.mp3';
      
      // Stop any current preview
      await _audioPlayer.stop();
      
      // Set to play once (not loop)
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // Play preview
      await _audioPlayer.play(AssetSource(audioPath));
      
      print('Previewing ringtone: $ringtone');
      
      // Stop after duration
      Future.delayed(duration, () async {
        await _audioPlayer.stop();
        // Reset to loop mode
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      });
    } catch (e) {
      print('Error previewing ringtone: $e');
    }
  }

  /// Stop ringtone preview
  Future<void> stopPreview() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Error stopping preview: $e');
    }
  }

  /// Get the display name for a ringtone value
  String getRingtoneName(String value) {
    final ringtone = ringtones.firstWhere(
      (r) => r['value'] == value,
      orElse: () => ringtones[0],
    );
    return ringtone['name']!;
  }

  /// Get ringtone value from display name
  String? getRingtoneValue(String name) {
    final ringtone = ringtones.firstWhere(
      (r) => r['name'] == name,
      orElse: () => {'value': ?null},
    );
    return ringtone['value'];
  }

  /// Check if a ringtone file exists (for validation)
  bool isValidRingtone(String ringtone) {
    return ringtones.any((r) => r['value'] == ringtone);
  }

  /// Get currently ringing alarm (if any)
  LocationAlarm? get currentAlarm => _currentAlarm;

  /// Check if an alarm is currently ringing
  bool get isRinging => _isRinging;

  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
    _stopVibration();
    print('AlarmService disposed');
  }
}