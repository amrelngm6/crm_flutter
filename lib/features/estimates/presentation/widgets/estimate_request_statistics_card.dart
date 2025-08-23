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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: const Color(0xFF1B4D3E),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                tr('Estimate Request Statistics'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatisticsGrid(),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: tr('Total Requests'),
          value: '${statistics['total_requests'] ?? 0}',
          icon: Icons.description,
          color: const Color(0xFF1B4D3E),
        ),
        _buildStatCard(
          title: tr('Pending'),
          value: '${statistics['pending_requests'] ?? 0}',
          icon: Icons.pending,
          color: const Color(0xFFFF9800),
        ),
        _buildStatCard(
          title: tr('Assigned'),
          value: '${statistics['assigned_requests'] ?? 0}',
          icon: Icons.person_add,
          color: const Color(0xFF2196F3),
        ),
        _buildStatCard(
          title: tr('Unassigned'),
          value: '${statistics['unassigned_requests'] ?? 0}',
          icon: Icons.person_off,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}