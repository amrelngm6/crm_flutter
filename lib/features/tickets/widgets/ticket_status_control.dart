import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/tickets_provider.dart';
import '../../../core/models/ticket.dart';

class TicketStatusControl extends StatefulWidget {
  final Ticket ticket;

  const TicketStatusControl({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketStatusControl> createState() => _TicketStatusControlState();
}

class _TicketStatusControlState extends State<TicketStatusControl> {
  bool _isUpdatingStatus = false;
  bool _isAssigningStaff = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusControl(),
          const SizedBox(height: 30),
          _buildPriorityControl(),
          const SizedBox(height: 30),
          _buildStaffAssignment(),
          const SizedBox(height: 30),
          _buildTicketActions(),
        ],
      ),
    );
  }

  Widget _buildStatusControl() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Control',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E4057),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.ticket.status.color)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.ticket.status.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current: ${widget.ticket.status.name}',
                          style: TextStyle(
                            color: _getStatusColor(widget.ticket.status.color),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Status:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E4057),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.statuses.map((status) {
                  final isCurrentStatus = status.id == widget.ticket.status.id;
                  return GestureDetector(
                    onTap: isCurrentStatus ? null : () => _changeStatus(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrentStatus
                            ? Colors.grey[100]
                            : _getStatusColor(status.color)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(status.color),
                          width: isCurrentStatus ? 0.5 : 1.5,
                        ),
                      ),
                      child: Text(
                        status.name,
                        style: TextStyle(
                          color: isCurrentStatus
                              ? Colors.grey[500]
                              : _getStatusColor(status.color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_isUpdatingStatus)
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF52658F)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Updating status...',
                        style: TextStyle(
                          color: Color(0xFF52658F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E4057),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(widget.ticket.priority.color)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPriorityIcon(widget.ticket.priority.level),
                      size: 16,
                      color: _getPriorityColor(widget.ticket.priority.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current: ${widget.ticket.priority.name}',
                      style: TextStyle(
                        color: _getPriorityColor(widget.ticket.priority.color),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Priority cannot be changed from the mobile app. Please use the web interface.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAssignment() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Staff Assignment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E4057),
                ),
              ),
              const SizedBox(height: 15),
              if (widget.ticket.assignedStaff.isNotEmpty) ...[
                const Text(
                  'Currently Assigned:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E4057),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.ticket.assignedStaff.map((staff) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF52658F),
                            backgroundImage: staff.avatar != null
                                ? NetworkImage(staff.avatar!)
                                : null,
                            child: staff.avatar == null
                                ? Text(
                                    staff.name?.substring(0, 1).toUpperCase() ??
                                        'S',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            staff.name ?? 'Staff',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E4057),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeStaff([staff.id!]),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No staff assigned to this ticket',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                onPressed:
                    _isAssigningStaff ? null : _showStaffAssignmentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52658F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isAssigningStaff
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  _isAssigningStaff ? 'Assigning...' : 'Assign Staff',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E4057),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showDeleteConfirmation,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(TicketStatus status) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    final success = await context.read<TicketsProvider>().changeTicketStatus(
          widget.ticket.id,
          status.id,
        );

    setState(() {
      _isUpdatingStatus = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status changed to ${status.name}'),
          backgroundColor: const Color(0xFF52658F),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to change status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStaffAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<TicketsProvider>(
        builder: (context, provider, child) {
          return AlertDialog(
            title: const Text('Assign Staff'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: provider.staffMembers.isEmpty
                  ? const Center(child: Text('No staff members available'))
                  : ListView.builder(
                      itemCount: provider.staffMembers.length,
                      itemBuilder: (context, index) {
                        final staff = provider.staffMembers[index];
                        final isAssigned = widget.ticket.assignedStaff.any(
                            (assignedStaff) => assignedStaff.id == staff.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF52658F),
                            backgroundImage: staff.avatar != null
                                ? NetworkImage(staff.avatar!)
                                : null,
                            child: staff.avatar == null
                                ? Text(
                                    staff.name?.substring(0, 1).toUpperCase() ??
                                        'S',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(staff.name ?? 'Staff'),
                          subtitle: Text(staff.email ?? ''),
                          trailing: isAssigned
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: isAssigned
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _assignStaff([staff.id!]);
                                },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignStaff(List<int> staffIds) async {
    setState(() {
      _isAssigningStaff = true;
    });

    final success = await context.read<TicketsProvider>().assignStaff(
          widget.ticket.id,
          staffIds,
        );

    setState(() {
      _isAssigningStaff = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff assigned successfully'),
          backgroundColor: Color(0xFF52658F),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign staff'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeStaff(List<int> staffIds) async {
    final success = await context.read<TicketsProvider>().removeStaff(
          widget.ticket.id,
          staffIds,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff removed successfully'),
          backgroundColor: Color(0xFF52658F),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove staff'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text(
            'Are you sure you want to delete ticket #${widget.ticket.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<TicketsProvider>()
                  .deleteTicket(widget.ticket.id);
              if (success && mounted) {
                Navigator.pop(context); // Go back to tickets list
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
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
}
