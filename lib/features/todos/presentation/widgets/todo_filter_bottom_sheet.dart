import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/todos_provider.dart';

class TodoFilterBottomSheet extends StatefulWidget {
  const TodoFilterBottomSheet({super.key});

  @override
  State<TodoFilterBottomSheet> createState() => _TodoFilterBottomSheetState();
}

class _TodoFilterBottomSheetState extends State<TodoFilterBottomSheet> {
  String? selectedPriority;
  String? selectedStatus;
  String? selectedTimeFilter;

  final List<String> priorities = ['Important', 'Medium', 'Low'];
  final List<String> statuses = ['Completed', 'Pending'];
  final List<String> timeFilters = ['Today', 'This Week', 'Overdue'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<TodosProvider>();
    selectedPriority = provider.selectedPriority;
    selectedStatus = provider.selectedStatus;
    selectedTimeFilter = provider.selectedTimeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Todos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Priority'),
                const SizedBox(height: 12),
                _buildPriorityChips(),
                const SizedBox(height: 24),
                _buildSectionTitle('Time'),
                const SizedBox(height: 12),
                _buildTimeFilterChips(),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _clearFilters,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF52D681)),
                          ),
                        ),
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: Color(0xFF52D681),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52D681),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B4D3E),
      ),
    );
  }

  Widget _buildPriorityChips() {
    return Wrap(
      spacing: 8,
      children: priorities.map((priority) {
        final isSelected = selectedPriority == priority;
        return FilterChip(
          label: Text(priority),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              selectedPriority = selected ? priority : null;
            });
          },
          backgroundColor: Colors.grey[100],
          selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
          checkmarkColor: _getPriorityColor(priority),
          labelStyle: TextStyle(
            color: isSelected ? _getPriorityColor(priority) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? _getPriorityColor(priority) : Colors.grey[300]!,
          ),
        );
      }).toList(),
    );
  }

/*
  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      children: statuses.map((status) {
        final isSelected = selectedStatus == status;
        return FilterChip(
          label: Text(status),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              selectedStatus = selected ? status : null;
            });
          },
          backgroundColor: Colors.grey[100],
          selectedColor: const Color(0xFF52D681).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF52D681),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF52D681) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? const Color(0xFF52D681) : Colors.grey[300]!,
          ),
        );
      }).toList(),
    );
  }
*/
  Widget _buildTimeFilterChips() {
    return Wrap(
      spacing: 8,
      children: timeFilters.map((timeFilter) {
        final isSelected = selectedTimeFilter == timeFilter;
        return FilterChip(
          label: Text(timeFilter),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              selectedTimeFilter = selected ? timeFilter : null;
            });
          },
          backgroundColor: Colors.grey[100],
          selectedColor: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF1B4D3E),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
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

  void _clearFilters() {
    setState(() {
      selectedPriority = null;
      selectedStatus = null;
      selectedTimeFilter = null;
    });
  }

  void _applyFilters() {
    final provider = context.read<TodosProvider>();
    provider.applyFilters(
      priority: selectedPriority,
      status: selectedStatus,
      timeFilter: selectedTimeFilter,
    );
    Navigator.of(context).pop();
  }
}
