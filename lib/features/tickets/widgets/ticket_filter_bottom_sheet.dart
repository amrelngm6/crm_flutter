import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/tickets_provider.dart';

class TicketFilterBottomSheet extends StatefulWidget {
  const TicketFilterBottomSheet({super.key});

  @override
  State<TicketFilterBottomSheet> createState() =>
      _TicketFilterBottomSheetState();
}

class _TicketFilterBottomSheetState extends State<TicketFilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filter Tickets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E4057),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<TicketsProvider>().clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Color(0xFF52658F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatusFilter(),
                const SizedBox(height: 20),
                _buildPriorityFilter(),
                const SizedBox(height: 20),
                _buildCategoryFilter(),
                const SizedBox(height: 20),
                _buildClientFilter(),
                const SizedBox(height: 20),
                _buildQuickFilters(),
                const SizedBox(height: 20),
                _buildSortingOptions(),
                const SizedBox(height: 30),
                _buildApplyButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.statuses.map((status) {
                final isSelected = provider.selectedStatusId == status.id;
                return GestureDetector(
                  onTap: () {
                    provider.filterByStatus(isSelected ? null : status.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF52658F)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF52658F)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      status.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityFilter() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.priorities.map((priority) {
                final isSelected = provider.selectedPriorityId == priority.id;
                return GestureDetector(
                  onTap: () {
                    provider.filterByPriority(isSelected ? null : priority.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getPriorityColor(priority.color)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _getPriorityColor(priority.color)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(priority.level),
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          priority.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        if (provider.categories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.categories.map((category) {
                final isSelected = provider.selectedCategoryId == category.id;
                return GestureDetector(
                  onTap: () {
                    provider.filterByCategory(isSelected ? null : category.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF52658F)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF52658F)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      category.name ?? 'Unknown',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientFilter() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        if (provider.clients.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: provider.selectedClientId,
                  hint: Text('Select client'.tr()),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All clients'.tr()),
                    ),
                    ...provider.clients.map((client) {
                      return DropdownMenuItem<int?>(
                        value: client.id,
                        child: Text(client.name ?? 'Unknown'.tr()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    provider.filterByClient(value);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickFilters() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Filters'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToggleFilter(
                  'My Tickets Only',
                  provider.myTicketsOnly,
                  () => provider.toggleMyTicketsOnly(),
                ),
                _buildToggleFilter(
                  'Overdue',
                  provider.overdue == true,
                  () => provider.toggleOverdueFilter(),
                ),
                _buildToggleFilter(
                  'Due Soon',
                  provider.dueSoon == true,
                  () => provider.toggleDueSoonFilter(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleFilter(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF52658F) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF52658F) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label.tr(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortingOptions() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.sortBy,
                        items: const [
                          DropdownMenuItem(
                            value: 'created_at',
                            child: Text('Created Date'),
                          ),
                          DropdownMenuItem(
                            value: 'due_date',
                            child: Text('Due Date'),
                          ),
                          DropdownMenuItem(
                            value: 'priority_id',
                            child: Text('Priority'),
                          ),
                          DropdownMenuItem(
                            value: 'status_id',
                            child: Text('Status'),
                          ),
                          DropdownMenuItem(
                            value: 'subject',
                            child: Text('Subject'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.setSorting(value, provider.sortOrder);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    final newOrder =
                        provider.sortOrder == 'asc' ? 'desc' : 'asc';
                    provider.setSorting(provider.sortBy, newOrder);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF52658F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      provider.sortOrder == 'asc'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF52658F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
