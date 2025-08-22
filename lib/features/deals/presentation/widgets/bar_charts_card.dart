import 'package:flutter/material.dart';

class ChartsCard extends StatelessWidget {
  final List<dynamic> monthlyTrends;
  final int maxCount;
  final double maxValue;

  const ChartsCard({
    super.key,
    required this.monthlyTrends,
    required this.maxCount,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyTrends.isEmpty) return const SizedBox.shrink();

    // Calculate max values for scaling

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Monthly Trends Chart',
          style: TextStyle(
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
                          color: Color(0xFF7B68EE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Count',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF2E4057)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9b59b6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Value',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF2E4057)),
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
                    final totalValue =
                        double.parse((trend['total_value'] ?? 0.0).toString());

                    // Calculate bar heights (max 120px)
                    final countHeight =
                        maxCount > 0 ? (count / maxCount) * 120.0 : 0.0;
                    final valueHeight =
                        maxValue > 0 ? (totalValue / maxValue) * 120.0 : 0.0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value labels at top
                          SizedBox(
                            height: 30,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (totalValue > 0)
                                  Text(
                                    '\$${totalValue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF9b59b6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (count > 0)
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF7B68EE),
                                      fontWeight: FontWeight.w500,
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
                                  width: 12,
                                  height: countHeight,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B68EE),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Value bar
                                Container(
                                  width: 12,
                                  height: valueHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9b59b6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Month label
                          SizedBox(
                            width: monthlyTrends.length > 6 ? 28 : 50,
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
