import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/meetings/presentation/pages/meeting_edit_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/meetings_provider.dart';
import '../../../../core/models/meeting.dart';

class MeetingShowPage extends StatefulWidget {
  final Meeting meeting;

  const MeetingShowPage({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingShowPage> createState() => _MeetingShowPageState();
}

class _MeetingShowPageState extends State<MeetingShowPage> {
  late Meeting _meeting;

  @override
  void initState() {
    super.initState();
    _meeting = widget.meeting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF4CAF50),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _meeting.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Meeting Details'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 12),
              Text('Edit Meeting'.tr()),
            ],
          ),
        ),
        if (_meeting.hasUrl)
          PopupMenuItem(
            value: 'join',
            child: Row(
              children: [
                const Icon(Icons.videocam, size: 20),
                const SizedBox(width: 12),
                Text('Join Meeting'.tr()),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text('Delete Meeting'.tr(), style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMeetingHeader(),
          const SizedBox(height: 24),
          _buildDateTime(),
          const SizedBox(height: 24),
          _buildLocation(),
          const SizedBox(height: 24),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildClient(),
          const SizedBox(height: 24),
          _buildAttendees(),
          const SizedBox(height: 24),
          _buildMeetingOptions(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMeetingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32).withValues(alpha: 0.1),
            const Color(0xFF4CAF50).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _meeting.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_meeting.status.color)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(_meeting.status.color)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _meeting.status.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_meeting.status.color),
                  ),
                ),
              ),
            ],
          ),
          if (_meeting.timeUntilMeeting != null && _meeting.isUpcoming) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    _meeting.timeUntilMeeting!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTime() {
    return _buildSection(
      title: 'Date & Time',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _meeting.formattedDate,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.schedule,
            label: 'Time',
            value: _meeting.formattedTimeRange,
          ),
          if (_meeting.durationMinutes != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.timer,
              label: 'Duration',
              value: _meeting.formattedDuration,
            ),
          ],
          if (_meeting.isRecurring) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.repeat,
              label: 'Recurring',
              value: _meeting.recurringType?.toUpperCase() ?? 'RECURRING',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return _buildSection(
      title: 'Location',
      icon: _meeting.hasLocation ? Icons.location_on : Icons.videocam,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_meeting.hasLocation) ...[
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Venue',
              value: _meeting.location!,
            ),
          ] else if (_meeting.hasUrl) ...[
            _buildInfoRow(
              icon: Icons.videocam,
              label: 'Video Meeting',
              value: 'Online Meeting',
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(_meeting.meetingUrl!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _meeting.meetingUrl!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'No location specified',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (_meeting.description == null || _meeting.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Description',
      icon: Icons.description,
      child: Text(
        _meeting.description!,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildClient() {
    if (_meeting.client == null) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Client Information',
      icon: Icons.business,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.person,
            label: 'Contact',
            value: _meeting.client!.name ?? 'Unknown',
          ),
          if (_meeting.client!.email != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: _meeting.client!.email!,
            ),
          ],
          if (_meeting.client!.company != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.business,
              label: 'Company',
              value: _meeting.client!.company!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendees() {
    if (_meeting.attendees.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Attendees (${_meeting.attendees.length})',
      icon: Icons.people,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _meeting.attendees.map((attendee) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  backgroundImage: attendee.avatar != null
                      ? NetworkImage(attendee.avatar!)
                      : null,
                  child: attendee.avatar == null
                      ? Text(
                          attendee.initials,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendee.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (attendee.email != null)
                        Text(
                          attendee.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMeetingOptions() {
    return _buildSection(
      title: 'Meeting Options',
      icon: Icons.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_meeting.hasReminder) ...[
            _buildInfoRow(
              icon: Icons.notifications,
              label: 'Reminder',
              value: '${_meeting.reminderMinutes} minutes before',
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            icon: Icons.visibility,
            label: 'Privacy',
            value: 'Meeting',
          ),
          if (_meeting.isRecurring && _meeting.recurringEndDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.event_busy,
              label: 'Series Ends',
              value:
                  '${_meeting.recurringEndDate!.day}/${_meeting.recurringEndDate!.month}/${_meeting.recurringEndDate!.year}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_meeting.hasUrl && _meeting.isUpcoming) ...[
          ElevatedButton.icon(
            onPressed: () => _launchUrl(_meeting.meetingUrl!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.videocam),
            label: const Text('Join Meeting'),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleMenuAction('edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
                icon: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
                label: const Text('Edit',
                    style: TextStyle(color: Color(0xFF2E7D32))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleMenuAction('delete'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                title.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case '#28a745':
      case 'green':
        return Colors.green;
      case '#007bff':
      case 'blue':
        return Colors.blue;
      case '#dc3545':
      case 'red':
        return Colors.red;
      case '#ffc107':
      case 'yellow':
        return Colors.orange;
      case '#17a2b8':
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeetingEditPage(meeting: _meeting),
          ),
        );
        break;
      case 'join':
        if (_meeting.hasUrl) {
          _launchUrl(_meeting.meetingUrl!);
        }
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${_meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await Provider.of<MeetingsProvider>(context, listen: false)
                      .deleteMeeting(_meeting.id);

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete meeting'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      // For now, just show the URL to the user
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Meeting URL'),
            content: SelectableText(url),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch meeting URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
