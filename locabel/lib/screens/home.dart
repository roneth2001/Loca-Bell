import 'package:flutter/material.dart';
import '../models/location_alarm.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../widgets/alarm_card.dart';
import 'add_alarm_screen.dart';
import 'edit_alarm_screen.dart';

/// Home screen displaying all location alarms
/// 
/// Shows:
/// - List of alarms from local database
/// - Location monitoring status
/// - Add alarm button
/// - Edit/delete alarm actions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // State variables
  List<LocationAlarm> _alarms = [];
  bool _isLoading = true;
  bool _isLocationMonitoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload alarms when app comes to foreground
      _loadAlarms();
    }
  }

  /// Initialize screen - load alarms and check location monitoring
  Future<void> _initializeScreen() async {
    await _loadAlarms();
    await _checkLocationMonitoringStatus();
    _startLocationMonitoringIfNeeded();
  }

  /// Load alarms from local database
  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alarms = await StorageService.instance.getAlarms();
      
      setState(() {
        _alarms = alarms;
        _isLoading = false;
      });

      print('Loaded ${alarms.length} alarms from database');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load alarms: $e';
        _isLoading = false;
      });
      print('Error loading alarms: $e');
    }
  }

  /// Check if location monitoring is active
  Future<void> _checkLocationMonitoringStatus() async {
    try {
      final isMonitoring = LocationService.instance.isMonitoring;
      setState(() {
        _isLocationMonitoring = isMonitoring;
      });
    } catch (e) {
      print('Error checking location monitoring status: $e');
    }
  }

  /// Start location monitoring if there are active alarms
  void _startLocationMonitoringIfNeeded() {
    final hasActiveAlarms = _alarms.any((alarm) => alarm.isActive);
    
    if (hasActiveAlarms && !_isLocationMonitoring) {
      LocationService.instance.startLocationMonitoring();
      setState(() {
        _isLocationMonitoring = true;
      });
      print('Location monitoring started');
    } else if (!hasActiveAlarms && _isLocationMonitoring) {
      LocationService.instance.stopLocationMonitoring();
      setState(() {
        _isLocationMonitoring = false;
      });
      print('Location monitoring stopped (no active alarms)');
    }
  }

  /// Toggle alarm active state
  Future<void> _toggleAlarm(LocationAlarm alarm) async {
    try {
      final updatedAlarm = alarm.copyWith(
        isActive: !alarm.isActive,
        updatedAt: DateTime.now(),
      );
      
      await StorageService.instance.updateAlarm(updatedAlarm);
      
      // Reload alarms
      await _loadAlarms();
      
      // Update location monitoring
      _startLocationMonitoringIfNeeded();
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAlarm.isActive 
                  ? '${alarm.name} enabled' 
                  : '${alarm.name} disabled'
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error toggling alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update alarm'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete alarm with confirmation
  Future<void> _deleteAlarm(LocationAlarm alarm) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text(
          'Are you sure you want to delete "${alarm.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await StorageService.instance.deleteAlarm(alarm.id);
      
      // Reload alarms
      await _loadAlarms();
      
      // Update location monitoring
      _startLocationMonitoringIfNeeded();
      
      // Show feedback with undo option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alarm.name} deleted'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Restore the alarm
                await StorageService.instance.addAlarm(alarm);
                _loadAlarms();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete alarm'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to edit alarm screen
  Future<void> _navigateToEditAlarm(LocationAlarm alarm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAlarmScreen(alarm: alarm),
      ),
    );

    if (result == true) {
      // Alarm was updated
      _loadAlarms();
    }
  }

  /// Navigate to add alarm screen
  Future<void> _navigateToAddAlarm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAlarmScreen(),
      ),
    );

    if (result == true) {
      // Alarm was added
      _loadAlarms();
    }
  }

  /// Toggle location monitoring manually
  void _toggleLocationMonitoring() {
    if (_isLocationMonitoring) {
      LocationService.instance.stopLocationMonitoring();
      setState(() {
        _isLocationMonitoring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location monitoring stopped'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      LocationService.instance.startLocationMonitoring();
      setState(() {
        _isLocationMonitoring = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location monitoring started'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadAlarms,
        child: _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Location Alarms',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Location monitoring toggle
        IconButton(
          icon: Icon(
            _isLocationMonitoring 
                ? Icons.location_on 
                : Icons.location_off,
          ),
          onPressed: _toggleLocationMonitoring,
          tooltip: _isLocationMonitoring 
              ? 'Stop monitoring' 
              : 'Start monitoring',
        ),
        
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAlarms,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Build body content
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_alarms.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAlarmList();
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading alarms...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Alarms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAlarms,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Location Alarms',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first alarm to get notified\nwhen you reach a location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _navigateToAddAlarm,
                icon: const Icon(Icons.add_location),
                label: const Text('Add Your First Alarm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build alarm list
  Widget _buildAlarmList() {
    return Column(
      children: [
        // Status banner
        if (_isLocationMonitoring) _buildStatusBanner(),
        
        // Alarm list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _alarms.length,
            itemBuilder: (context, index) {
              final alarm = _alarms[index];
              return AlarmCard(
                alarm: alarm,
                onTap: () => _navigateToEditAlarm(alarm),
                onToggle: (isActive) => _toggleAlarm(alarm),
                onDelete: () => _deleteAlarm(alarm),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build status banner
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFC8E6C9),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Location monitoring active',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${_alarms.where((a) => a.isActive).length} active',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build floating action button
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddAlarm,
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_location),
      label: const Text(
        'Add Alarm',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 4,
    );
  }
}