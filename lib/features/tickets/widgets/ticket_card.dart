import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildSubject(),
                const SizedBox(height: 8),
                _buildMessage(),
                const SizedBox(height: 16),
                _buildMetadata(),
                if (ticket.client != null) ...[
                  const SizedBox(height: 12),
                  _buildClientInfo(),
                ],
                if (ticket.assignedStaff.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAssignedStaff(),
                ],
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(ticket.status.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(ticket.status.color),
              width: 1.5,
            ),
          ),
          child: Text(
            ticket.status.name,
            style: TextStyle(
              color: _getStatusColor(ticket.status.color),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _getPriorityColor(ticket.priority.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getPriorityColor(ticket.priority.color),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPriorityIcon(ticket.priority.level),
                size: 12,
                color: _getPriorityColor(ticket.priority.color),
              ),
              const SizedBox(width: 4),
              Text(
                ticket.priority.name,
                style: TextStyle(
                  color: _getPriorityColor(ticket.priority.color),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (ticket.isOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  size: 12,
                  color: Colors.red,
                ),
                SizedBox(width: 4),
                Text(
                  'Overdue',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubject() {
    return Text(
      ticket.subject,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E4057),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMessage() {
    return Text(
      ticket.message,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        if (ticket.dueDate != null) ...[
          Icon(
            Icons.schedule,
            size: 16,
            color: ticket.isOverdue ? Colors.red : Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(),
            style: TextStyle(
              fontSize: 12,
              color: ticket.isOverdue ? Colors.red : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (ticket.category != null) ...[
          Icon(
            Icons.category_outlined,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            ticket.category!.name ?? 'No Category'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientInfo() {
    if (ticket.client == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF52658F),
            backgroundImage: ticket.client!.avatar != null
                ? NetworkImage(ticket.client!.avatar!)
                : null,
            child: ticket.client!.avatar == null
                ? Text(
                    ticket.client!.name?.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                  ticket.client!.name ?? 'Unknown Client'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E4057),
                  ),
                ),
                if (ticket.client!.email != null)
                  Text(
                    ticket.client!.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedStaff() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned to'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ticket.assignedStaff.take(3).map((staff) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF52658F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: const Color(0xFF52658F),
                    backgroundImage: staff.avatar != null
                        ? NetworkImage(staff.avatar!)
                        : null,
                    child: staff.avatar == null
                        ? Text(
                            staff.name?.substring(0, 1).toUpperCase() ?? 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    staff.name ?? 'Staff'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF52658F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (ticket.assignedStaff.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${ticket.assignedStaff.length - 3} more',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Text(
          '${'Ticket'.tr()} #${ticket.id}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (ticket.comments != null) ...[
          Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            '${ticket.comments!.count}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          _formatCreatedAt(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? colorCode) {
    if (colorCode == null) return Colors.grey;

    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getPriorityColor(String? colorCode) {
    if (colorCode == null) return Colors.orange;

    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.orange;
    }
  }

  IconData _getPriorityIcon(int level) {
    switch (level) {
      case 1: // Low
        return Icons.arrow_downward;
      case 2: // Medium
        return Icons.remove;
      case 3: // High
        return Icons.arrow_upward;
      case 4: // Critical
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }

  String _formatDueDate() {
    if (ticket.dueDate == null) return '';

    final dueDate = DateTime.parse(ticket.dueDate!);
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else if (difference == 0) {
      return 'Due today'.tr();
    } else if (difference == 1) {
      return 'Due tomorrow'.tr();
    } else {
      return '${'Due in'.tr()} $difference days';
    }
  }

  String _formatCreatedAt() {
    final createdAt = DateTime.parse(ticket.createdAt);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
