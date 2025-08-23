import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/estimate_request.dart';

class EstimateRequestCard extends StatelessWidget {
  final EstimateRequest request;
  final VoidCallback onTap;
  final Function(int) onStatusChange;
  final Function(int) onAssignStaff;

  const EstimateRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    required this.onStatusChange,
    required this.onAssignStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildContent(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (request.companyName != null)
                Text(
                  request.companyName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    try {
      statusColor = Color(int.parse('0xFF${request.statusColor?.substring(1) ?? '1B4D3E'}'));
    } catch (e) {
      statusColor = const Color(0xFF1B4D3E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        request.statusName ?? request.status ?? 'Unknown',
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.description.isNotEmpty) ...[
          Text(
            request.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        _buildInfoRow(),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (request.budget != null)
          _buildInfoItem(
            icon: Icons.attach_money,
            label: tr('Budget'),
            value: request.budget!,
          ),
        if (request.timeline != null)
          _buildInfoItem(
            icon: Icons.schedule,
            label: tr('Timeline'),
            value: request.timeline!,
          ),
        if (request.priority != null)
          _buildInfoItem(
            icon: Icons.priority_high,
            label: tr('Priority'),
            value: request.priority!,
          ),
        if (request.source != null)
          _buildInfoItem(
            icon: Icons.source,
            label: tr('Source'),
            value: request.source!,
          ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildContactInfo(),
        const Spacer(),
        _buildActions(),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.contactName != null)
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.contactName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (request.contactEmail != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.contactEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (request.isUrgent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.priority_high,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  tr('Urgent'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        if (request.isFollowUp)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  tr('Follow Up'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'status':
            _showStatusChangeDialog();
            break;
          case 'assign':
            _showAssignStaffDialog();
            break;
          case 'estimate':
            _showAssignEstimateDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 16),
              const SizedBox(width: 8),
              Text(tr('Change Status')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'assign',
          child: Row(
            children: [
              const Icon(Icons.person_add, size: 16),
              const SizedBox(width: 8),
              Text(tr('Assign Staff')),
            ],
          ),
        ),
        if (request.estimateId == null)
          PopupMenuItem(
            value: 'estimate',
            child: Row(
              children: [
                const Icon(Icons.description, size: 16),
                const SizedBox(width: 8),
                Text(tr('Assign Estimate')),
              ],
            ),
          ),
      ],
    );
  }

  void _showStatusChangeDialog() {
    // TODO: Implement status change dialog
    // This would show a dialog with available statuses
    // and call onStatusChange when a status is selected
  }

  void _showAssignStaffDialog() {
    // TODO: Implement assign staff dialog
    // This would show a dialog with available staff members
    // and call onAssignStaff when a staff member is selected
  }

  void _showAssignEstimateDialog() {
    // TODO: Implement assign estimate dialog
    // This would show a dialog with available estimates
    // and call the appropriate callback when an estimate is selected
  }
}