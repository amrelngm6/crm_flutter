import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/models/task.dart';
import '../../../../../core/providers/tasks_provider.dart';

class TaskShowPage extends StatefulWidget {
  final Task task;

  const TaskShowPage({super.key, required this.task});

  @override
  State<TaskShowPage> createState() => _TaskShowPageState();
}

class _TaskShowPageState extends State<TaskShowPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildChecklistTab(),
                            _buildTimesheetTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddChecklistItemDialog(context),
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.task.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showOptionsMenu,
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusBadge(widget.task.status!),
              const SizedBox(width: 12),
              _buildPriorityBadge(widget.task.priority!),
              const Spacer(),
              Text(
                widget.task.progressText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getPriorityColor(priority.name),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            priority.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor:
            widget.task.progress != null ? widget.task.progress! / 100 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF667eea),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: 'Overview'.tr()),
          Tab(text: 'Checklist'.tr()),
          Tab(text: 'Timesheets'.tr()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Task Details',
            [
              _buildInfoRow('Name', widget.task.name),
              if (widget.task.description != null)
                _buildInfoRow('Description', widget.task.description!),
              _buildInfoRow('Priority', widget.task.priority!.name),
              _buildInfoRow('Status', widget.task.status!.name),
              _buildInfoRow('Progress', widget.task.progressText),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Dates',
            [
              if (widget.task.dates!.startDate != null)
                _buildInfoRow(
                    'Start Date', _formatDate(widget.task.dates!.startDate!)),
              if (widget.task.dates!.dueDate != null)
                _buildInfoRow(
                    'Due Date', _formatDate(widget.task.dates!.dueDate!)),
              if (widget.task.dates!.finishedDate != null)
                _buildInfoRow('Finished Date',
                    _formatDate(widget.task.dates!.finishedDate!)),
              _buildInfoRow('Time Remaining', widget.task.timeRemaining),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.task.team.isNotEmpty)
            _buildInfoCard(
              'Team Members',
              widget.task.team
                  .map((member) => _buildTeamMemberRow(member))
                  .toList(),
            ),
          const SizedBox(height: 16),
          if (widget.task.model != null)
            _buildInfoCard(
              'Related Model',
              [
                _buildInfoRow('Type', widget.task.model!.type),
                if (widget.task.model!.name != null)
                  _buildInfoRow('Name', widget.task.model!.name!),
              ],
            ),
          const SizedBox(height: 16),
          if (widget.task.project != null)
            _buildInfoCard(
              'Project',
              [
                _buildInfoRow(
                    'Project Name', widget.task.project!.name ?? 'Unknown'),
              ],
            ),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildChecklistTab() {
    if (widget.task.checklist == null || widget.task.checklist!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.checklist,
              size: 64,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'No checklist items'.tr(),
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () {},
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 17, 107, 74))),
                child: Text('Add Checklist Item'.tr(),
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.task.checklist!.items.length,
      itemBuilder: (context, index) {
        final item = widget.task.checklist!.items[index];
        return _buildChecklistItem(item);
      },
    );
  }

  Widget _buildTimesheetTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (widget.task.timesheets != null) ...[
            _buildInfoCard(
              'Time Tracking',
              [
                _buildInfoRow(
                    'Total Entries', widget.task.timesheets!.count.toString()),
                _buildInfoRow('Total Hours',
                    '${widget.task.timesheets!.totalHours.toStringAsFixed(1)}h'),
              ],
            ),
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No time entries',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(TaskTeamMember member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF667eea),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase().tr() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (member.email != null)
                  Text(
                    member.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(TaskChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            setState(() {
              item.finished = !item.finished;
            });
            _updateChecklistItem(
              context,
              item.id,
              {'finished': item.finished},
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    item.finished ? const Color(0xFF52D681) : Colors.grey[400]!,
                width: 2,
              ),
              color:
                  item.finished ? const Color(0xFF52D681) : Colors.transparent,
            ),
            child: item.finished
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        ),
        //             Checkbox(
        //   value: item.finished,
        //   onChanged: (value) {
        //     setState(() {
        //       item.finished = value!;
        //     });
        //     _updateChecklistItem(
        //       context,
        //       item.id,
        //       {'finished': value},
        //     );
        //   },
        //   activeColor: const Color(0xFF10B981),
        // ),
        title: Text(
          item.description,
          style: TextStyle(
            fontSize: 14,
            color: item.finished ? Colors.grey[600] : const Color(0xFF1F2937),
            decoration: item.finished ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: item.finishedDate != null
            ? Text(
                "${'Completed'.tr()}: ${_formatDate(item.finishedDate!)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              )
            : null,
        trailing: item.points > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.points}pt',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Comments',
                    widget.task.commentsCount.toString(),
                    Icons.comment,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 16),
                if (widget.task.checklist != null)
                  Expanded(
                    child: _buildStatItem(
                      'Checklist',
                      '${widget.task.checklist!.completedItems}/${widget.task.checklist!.totalItems}',
                      Icons.checklist,
                      const Color(0xFF10B981),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
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
            value.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'normal':
        return const Color(0xFF6B7280);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!widget.task.isCompleted)
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                title: Text('Mark as Completed'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
              title: Text('Delete Task'.tr()),
              onTap: () {
                Navigator.pop(context);
                _deleteTask();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _markAsCompleted() {
    context.read<TasksProvider>().markTaskCompleted(widget.task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task marked as completed!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<TasksProvider>()
                  .deleteTask(widget.task.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showAddChecklistItemDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Checklist Item'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _addChecklistItem(
                context,
                titleController.text.trim(),
                descriptionController.text.trim(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
              ),
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateChecklistItem(
      BuildContext context, int itemId, Map<String, dynamic> updates) async {
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    final success = await tasksProvider.updateChecklistItem(
      widget.task.id,
      itemId,
      updates,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(tasksProvider.error ?? 'Failed to update checklist item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addChecklistItem(
      BuildContext context, String title, String description) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

    final itemData = {
      'title': title,
      'description': description,
      'is_completed': false,
    };

    Navigator.of(context).pop(); // Close dialog first

    final success =
        await tasksProvider.addChecklistItem(widget.task.id, itemData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist item added successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tasksProvider.error ?? 'Failed to add checklist item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
