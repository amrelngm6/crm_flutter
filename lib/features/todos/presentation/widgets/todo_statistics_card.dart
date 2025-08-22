import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/todo.dart';

class TodoStatisticsCard extends StatelessWidget {
  final TodoStatistics statistics;

  const TodoStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCard(),
        const SizedBox(height: 20),
        _buildPriorityBreakdownCard(),
        const SizedBox(height: 20),
        _buildTrendsCard(),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    statistics.overview.totalTodos.toString(),
                    const Color(0xFF52D681),
                    Icons.list_alt,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    statistics.overview.completedTodos.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    statistics.overview.pendingTodos.toString(),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Overdue',
                    statistics.overview.overdueTodos.toString(),
                    Colors.red,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCompletionRateIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            label.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateIndicator() {
    final rate = statistics.overview.completionRate / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion Rate'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
              ),
            ),
            Text(
              '${statistics.overview.completionRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF52D681),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: rate,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPriorityBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Breakdown'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 20),
            ...statistics.priorityBreakdown.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPriorityItem(item),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityItem(PriorityBreakdown item) {
    final color = _getPriorityColor(item.color);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.priorityName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Completion Trends'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 20),
            if (statistics.dailyTrends.isEmpty)
              Center(
                child: Text(
                  'No trend data available'.tr(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: statistics.dailyTrends.length,
                  itemBuilder: (context, index) {
                    final trend = statistics.dailyTrends[index];
                    final maxValue = statistics.dailyTrends
                        .map((t) => t.completed)
                        .reduce((a, b) => a > b ? a : b);
                    final height =
                        maxValue > 0 ? (trend.completed / maxValue) * 80 : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            trend.completed.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF52D681),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 20,
                            height: height,
                            decoration: BoxDecoration(
                              color: const Color(0xFF52D681),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              _formatTrendDate(trend.date),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String colorString) {
    // Remove # if present
    final hex = colorString.replaceAll('#', '');
    try {
      return Color(int.parse('0xff$hex'));
    } catch (e) {
      // Fallback colors
      switch (colorString.toLowerCase()) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }
  }

  String _formatTrendDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return date.length > 5 ? date.substring(0, 5) : date;
    }
  }
}
