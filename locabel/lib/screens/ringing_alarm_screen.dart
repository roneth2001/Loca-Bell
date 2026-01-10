import 'package:flutter/material.dart';
import 'dart:async';
import '../models/location_alarm.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

/// Screen displayed when an alarm is triggered
class AlarmRingingScreen extends StatefulWidget {
  final LocationAlarm alarm;

  const AlarmRingingScreen({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  Timer? _distanceTimer;
  double _currentDistance = 0.0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startDistanceUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _distanceTimer?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _startDistanceUpdates() {
    _updateDistance();
    _distanceTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateDistance();
    });
  }

  void _updateDistance() async {
    final position = LocationService.instance.currentPosition;
    if (position != null) {
      final distance = LocationService.instance.calculateDistance(
        position.latitude,
        position.longitude,
        widget.alarm.latitude,
        widget.alarm.longitude,
      );

      setState(() {
        _currentDistance = distance;
      });
    }
  }

  Future<void> _dismissAlarm() async {
    if (_isDismissing) return;

    setState(() => _isDismissing = true);

    try {
      await AlarmService.instance.stopAlarm();
      LocationService.instance.resetTriggeredAlarm(widget.alarm.id);

      final history = await StorageService.instance.getHistoryForAlarm(widget.alarm.id);
      if (history.isNotEmpty) {
        final latestHistory = history.first;
        await StorageService.instance.markHistoryDismissed(
          latestHistory['history_id'] as int,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error dismissing alarm: $e');
      setState(() => _isDismissing = false);
    }
  }

  Future<void> _snoozeAlarm() async {
    if (_isDismissing) return;

    try {
      await AlarmService.instance.snoozeAlarm(widget.alarm);
      LocationService.instance.resetTriggeredAlarm(widget.alarm.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm snoozed for 5 minutes'),
            backgroundColor: Color(0xFF2196F3),
          ),
        );

        Navigator.pop(context);
      }

      await Future.delayed(const Duration(minutes: 5));
    } catch (e) {
      print('Error snoozing alarm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A237E),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF3949AB),
                ],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMainContent()),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'LOCATION ALARM',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateTime.now().toString().substring(11, 16),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.alarm.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.alarm.locationString,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      icon: Icons.radar,
                      label: 'Radius',
                      value: '${widget.alarm.radius.toInt()}m',
                    ),
                    _buildInfoChip(
                      icon: Icons.navigation,
                      label: 'Distance',
                      value: '${_currentDistance.toInt()}m',
                      color: _currentDistance > widget.alarm.radius
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: const Icon(Icons.vibration, color: Colors.white70, size: 20),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Vibrating',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isDismissing ? null : _dismissAlarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 8,
              ),
              child: _isDismissing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'DISMISS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: _isDismissing ? null : _snoozeAlarm,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.snooze, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'SNOOZE (5 MIN)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ringtone: ${AlarmService.instance.getRingtoneName(widget.alarm.ringtone)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}