import 'package:flutter/material.dart';
import '../models/location_alarm.dart';
import '../services/alarm_service.dart';

/// Reusable alarm card widget for displaying location alarms
/// Shows alarm details with toggle and delete actions
class AlarmCard extends StatelessWidget {
  final LocationAlarm alarm;
  final VoidCallback onTap;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final bool showActions;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading Icon
              _buildAlarmIcon(),
              const SizedBox(width: 12),
              
              // Alarm Details
              Expanded(
                child: _buildAlarmDetails(context),
              ),
              
              // Actions (Toggle & Delete)
              if (showActions) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the circular icon indicating alarm status
  Widget _buildAlarmIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: alarm.isActive
              ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
              : [const Color(0xFF9E9E9E), const Color(0xFF757575)],
        ),
        boxShadow: [
          BoxShadow(
            color: alarm.isActive
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        alarm.isActive ? Icons.location_on : Icons.location_off,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Build the alarm details section
  Widget _buildAlarmDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alarm Name
        Text(
          alarm.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF212121),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        
        // Location Coordinates
        _buildInfoRow(
          icon: Icons.my_location,
          text: 'Lat: ${alarm.latitude.toStringAsFixed(5)}, '
                'Lng: ${alarm.longitude.toStringAsFixed(5)}',
        ),
        
        // Radius
        _buildInfoRow(
          icon: Icons.radio_button_unchecked,
          text: 'Radius: ${alarm.radius.toInt()}m',
        ),
        
        // Ringtone
        _buildInfoRow(
          icon: Icons.music_note,
          text: 'Ringtone: ${AlarmService.instance.getRingtoneName(alarm.ringtone)}',
        ),
      ],
    );
  }

  /// Build a single info row with icon and text
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF666666),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the actions section (toggle switch and delete button)
  Widget _buildActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Toggle Switch
        GestureDetector(
          onTap: () => onToggle(!alarm.isActive),
          child: Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: alarm.isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFCCCCCC),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: alarm.isActive
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Delete Button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: const Color(0xFFF44336),
          iconSize: 22,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onDelete,
          tooltip: 'Delete alarm',
        ),
      ],
    );
  }
}

/// Compact version of alarm card for smaller displays or lists
class AlarmCardCompact extends StatelessWidget {
  final LocationAlarm alarm;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const AlarmCardCompact({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alarm.isActive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(width: 12),
              
              // Alarm Name
              Expanded(
                child: Text(
                  alarm.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Radius Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${alarm.radius.toInt()}m',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Toggle Switch
              Switch(
                value: alarm.isActive,
                onChanged: onToggle,
                activeColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detailed alarm card with expandable information
class AlarmCardDetailed extends StatefulWidget {
  final LocationAlarm alarm;
  final VoidCallback onTap;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const AlarmCardDetailed({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<AlarmCardDetailed> createState() => _AlarmCardDetailedState();
}

class _AlarmCardDetailedState extends State<AlarmCardDetailed> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _isExpanded ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isExpanded
            ? const BorderSide(color: Color(0xFF2196F3), width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Main Card Content
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.alarm.isActive
                            ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
                            : [const Color(0xFF9E9E9E), const Color(0xFF757575)],
                      ),
                    ),
                    child: Icon(
                      widget.alarm.isActive
                          ? Icons.location_on
                          : Icons.location_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.alarm.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.alarm.radius.toInt()}m • '
                          '${AlarmService.instance.getRingtoneName(widget.alarm.ringtone)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  Switch(
                    value: widget.alarm.isActive,
                    onChanged: widget.onToggle,
                    activeColor: const Color(0xFF4CAF50),
                  ),
                  
                  // Expand Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Details
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Coordinates
                  _buildDetailRow(
                    'Location',
                    'Lat: ${widget.alarm.latitude.toStringAsFixed(6)}\n'
                    'Lng: ${widget.alarm.longitude.toStringAsFixed(6)}',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  
                  // Created Date
                  _buildDetailRow(
                    'Created',
                    _formatDate(widget.alarm.createdAt),
                    Icons.access_time,
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit ?? widget.onTap,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF44336),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}