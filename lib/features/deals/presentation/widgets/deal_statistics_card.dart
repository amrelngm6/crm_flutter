import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/deals/presentation/widgets/bar_charts_card.dart';

class DealStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const DealStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final overview = statistics['overview'] ?? {};
    final statusBreakdown = statistics['status_breakdown'] ?? {};
    final monthlyTrends = statistics['monthly_trends'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9b59b6),
          ),
        ),
        const SizedBox(height: 20),
        _buildOverviewCards(overview),
        const SizedBox(height: 30),
        _buildMonthlyTrendsCharts(context, monthlyTrends),
        const SizedBox(height: 30),
        _buildStatusBreakdown(statusBreakdown),
        const SizedBox(height: 30),
        _buildMonthlyTrends(context, monthlyTrends),
      ],
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9b59b6),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildOverviewCard(
              'Total Deals',
              '${overview['total_deals'] ?? 0}',
              Icons.business_center,
              const Color(0xFF9b59b6),
            ),
            _buildOverviewCard(
              'Total Value',
              '\$${(double.parse(overview['total_value'].toString()))}',
              Icons.attach_money,
              const Color(0xFF8e44ad),
            ),
            _buildOverviewCard(
              'Avg Deal Value',
              '\$${(double.parse(overview['average_deal_value'].toString()))}',
              Icons.trending_up,
              const Color(0xFFe74c3c),
            ),
            _buildOverviewCard(
              'Avg Probability',
              '${(double.parse(overview['average_probability'].toString()))}%',
              Icons.pie_chart,
              const Color(0xFFf39c12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(List<dynamic> statusBreakdown) {
    if (statusBreakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Breakdown'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9b59b6),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: statusBreakdown.map<Widget>((entry) {
              final statusKey = entry['status'];
              final count = entry['count'] ?? 0;
              final totalValue = entry['total_value'] ?? 0.0;
              final statusName = _getStatusDisplayName(statusKey);
              final color = _getStatusColor(statusKey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9b59b6),
                            ),
                          ),
                          Text(
                            'Value: \$${(double.parse(totalValue.toString()))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends(
      BuildContext context, List<dynamic> monthlyTrends) {
    if (monthlyTrends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E4057),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: monthlyTrends.take(6).map<Widget>((trend) {
              final month = trend['month'] ?? '';
              final count = trend['count'] ?? 0;
              final totalValue = trend['total_value'] ?? 0.0;
              final maxCount = monthlyTrends.fold<int>(0, (max, item) {
                final itemCount = item['count'] ?? 0;
                return itemCount > max ? itemCount : max;
              });

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            _formatMonth(month),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                height: 6,
                                width: maxCount > 0
                                    ? (count / maxCount) *
                                        MediaQuery.of(context).size.width *
                                        0.5
                                    : 0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B68EE),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E4057),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\$${double.parse(totalValue ?? '0.0').toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsCharts(
      BuildContext context, List<dynamic> monthlyTrends) {
    final maxCount = monthlyTrends.fold<int>(0, (max, item) {
      final itemCount = item['count'] ?? 0;
      return itemCount > max ? itemCount : max;
    });

    final maxValue = monthlyTrends.fold<double>(0.0, (max, item) {
      final itemValue = double.parse((item['total_value'] ?? 0.0).toString());
      return itemValue > max ? itemValue : max;
    });

    return ChartsCard(
      maxCount: maxCount,
      maxValue: maxValue,
      monthlyTrends: monthlyTrends,
    );
  }

  String _getStatusDisplayName(String statusKey) {
    switch (statusKey) {
      case '0':
        return 'Open'.tr();
      case 'won':
        return 'Won'.tr();
      case 'lost':
        return 'Lost'.tr();
      case 'pending':
        return 'Pending'.tr();
      default:
        return statusKey.isNotEmpty
            ? statusKey
                .replaceAll('_', ' ')
                .toLowerCase()
                .split(' ')
                .map((word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '')
                .join(' ')
                .tr()
            : 'Unknown'.tr();
    }
  }

  Color _getStatusColor(String statusKey) {
    switch (statusKey) {
      case '0':
        return const Color(0xFF3498db);
      case 'won':
        return const Color(0xFF27ae60);
      case 'lost':
        return const Color(0xFFe74c3c);
      case 'pending':
        return const Color(0xFFf39c12);
      default:
        return const Color(0xFF95a5a6);
    }
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthNum = int.parse(parts[1]);
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[monthNum - 1]} ${year.substring(2)}';
      }
    } catch (e) {
      // Handle parsing error
    }
    return month;
  }
}
