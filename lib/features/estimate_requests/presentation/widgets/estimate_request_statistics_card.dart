import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EstimateRequestStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const EstimateRequestStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Estimate Request Statistics'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 24),
        
        // Overall stats
        _buildOverallStats(),
        
        const SizedBox(height: 24),
        
        // Status breakdown
        if (statistics['status_breakdown'] != null)
          _buildStatusBreakdown(),
        
        const SizedBox(height: 24),
        
        // Priority breakdown
        if (statistics['priority_breakdown'] != null)
          _buildPriorityBreakdown(),
        
        const SizedBox(height: 24),
        
        // Assignment stats
        if (statistics['assignment_stats'] != null)
          _buildAssignmentStats(),
      ],
    );
  }

  Widget _buildOverallStats() {
    final total = statistics['total_requests'] ?? 0;
    final thisMonth = statistics['this_month'] ?? 0;
    final thisWeek = statistics['this_week'] ?? 0;
    final avgResponse = statistics['avg_response_time'] ?? '0 hours';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Overall Statistics'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Requests'.tr(),
                  value: total.toString(),
                  icon: Icons.request_quote,
                  color: const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'This Month'.tr(),
                  value: thisMonth.toString(),
                  icon: Icons.calendar_month,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'This Week'.tr(),
                  value: thisWeek.toString(),
                  icon: Icons.calendar_week,
                  color: const Color(0xFFF39C12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Response'.tr(),
                  value: avgResponse,
                  icon: Icons.schedule,
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final statusData = Map<String, dynamic>.from(statistics['status_breakdown'] ?? {});
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Status Breakdown'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ...statusData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(entry.key),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    final priorityData = Map<String, dynamic>.from(statistics['priority_breakdown'] ?? {});
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Priority Breakdown'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          ...priorityData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(entry.key),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key.toUpperCase().tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(entry.key),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAssignmentStats() {
    final assignmentData = Map<String, dynamic>.from(statistics['assignment_stats'] ?? {});
    final unassigned = assignmentData['unassigned'] ?? 0;
    final assigned = assignmentData['assigned'] ?? 0;
    final withEstimates = assignmentData['with_estimates'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Assignment Statistics'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Assigned'.tr(),
                  value: assigned.toString(),
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Unassigned'.tr(),
                  value: unassigned.toString(),
                  icon: Icons.person_outline,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'With Estimates'.tr(),
            value: withEstimates.toString(),
            icon: Icons.receipt,
            color: Colors.blue,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return const Color(0xFF3498DB);
      case 'in_progress':
      case 'processing':
        return const Color(0xFFF39C12);
      case 'completed':
      case 'done':
        return const Color(0xFF27AE60);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C);
      case 'medium':
        return const Color(0xFFF39C12);
      case 'low':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}