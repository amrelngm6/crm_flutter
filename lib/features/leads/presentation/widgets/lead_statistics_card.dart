import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LeadStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const LeadStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final overview = statistics['overview'] ?? {};
    final statusBreakdown = statistics['status_breakdown'] ?? [];
    final sourceBreakdown = statistics['source_breakdown'] ?? [];
    final monthlyTrends = statistics['monthly_trends'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF27ae60),
          ),
        ),
        const SizedBox(height: 20),
        _buildOverviewCards(overview),
        const SizedBox(height: 30),
        _buildMonthlyTrendsCharts(context, monthlyTrends),
        const SizedBox(height: 30),
        _buildStatusBreakdown(statusBreakdown),
        const SizedBox(height: 30),
        _buildSourceBreakdown(sourceBreakdown),
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
            color: Color(0xFF27ae60),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
            height: 80,
            child: Container(
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.group,
                            color: Colors.teal[800], size: 32),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${overview['total_leads'] ?? 0}",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                            ),
                          ),
                          Text(
                            "Total Leads".tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            )),
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
              'Converted',
              '${overview['converted_leads'] ?? 0}',
              Icons.check_circle,
              const Color(0xFF3498db),
            ),
            _buildOverviewCard(
              'Conversion Rate',
              '${overview['conversion_rate'] ?? 0}%',
              Icons.trending_up,
              const Color(0xFFf39c12),
            ),
            _buildOverviewCard(
              'Today',
              '${overview['new_leads_today'] ?? 0}',
              Icons.today,
              const Color(0xFF9b59b6),
            ),
            _buildOverviewCard(
              'This Month',
              '${overview['new_leads_this_month'] ?? 0}',
              Icons.calendar_month,
              const Color(0xFFe74c3c),
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
            color: Color(0xFF27ae60),
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
            children: statusBreakdown.map<Widget>((status) {
              final statusName = status['status_name'] ?? 'Unknown';
              final count = status['count'] ?? 0;
              final color = _parseColor(status['color'] ?? '#6c757d');

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
                      child: Text(
                        statusName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF27ae60),
                        ),
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

  Widget _buildSourceBreakdown(List<dynamic> sourceBreakdown) {
    if (sourceBreakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source Breakdown'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF27ae60),
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
            children: sourceBreakdown.map<Widget>((source) {
              final sourceName = source['source_name'] ?? 'Unknown';
              final count = source['count'] ?? 0;
              final color = _getSourceColor(sourceName);

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
                      child: Text(
                        sourceName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF27ae60),
                        ),
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
            color: Color(0xFF27ae60),
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
              final maxCount = monthlyTrends.fold<int>(0, (max, item) {
                final itemCount = item['count'] ?? 0;
                return itemCount > max ? itemCount : max;
              });

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                              color: const Color(0xFF27ae60),
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
                        color: Color(0xFF27ae60),
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

  Widget _buildMonthlyTrendsCharts(
      BuildContext context, List<dynamic> monthlyTrends) {
    if (monthlyTrends.isEmpty) return const SizedBox.shrink();

    final maxCount = monthlyTrends.fold<int>(0, (max, item) {
      final itemCount = item['count'] ?? 0;
      return itemCount > max ? itemCount : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends Chart'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF27ae60),
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
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27ae60),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Leads Count'.tr(),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF2E4057)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Horizontal bar chart
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyTrends.take(12).map<Widget>((trend) {
                    final month = trend['month'] ?? '';
                    final count = trend['count'] ?? 0;

                    // Calculate bar heights (max 120px)
                    final countHeight =
                        maxCount > 0 ? (count / maxCount) * 120.0 : 0.0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value labels at top
                          SizedBox(
                            height: 30,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (count > 0)
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF27ae60),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bars container
                          SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Count bar
                                Container(
                                  width: 20,
                                  height: countHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27ae60),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Month label
                          SizedBox(
                            width: 32,
                            child: Text(
                              _formatMonth(month),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null) return Colors.grey;

    try {
      if (colorCode.startsWith('#')) {
        return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
      }
      return Color(int.parse('0xFF$colorCode'));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getSourceColor(String sourceName) {
    // Generate consistent colors for different sources
    final colors = [
      const Color(0xFF3498db),
      const Color(0xFF9b59b6),
      const Color(0xFFe74c3c),
      const Color(0xFFf39c12),
      const Color(0xFF2ecc71),
      const Color(0xFF1abc9c),
      const Color(0xFFe67e22),
      const Color(0xFF34495e),
    ];

    final index = sourceName.hashCode % colors.length;
    return colors[index.abs()];
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
