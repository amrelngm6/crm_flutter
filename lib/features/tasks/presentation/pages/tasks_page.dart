import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/tasks/presentation/widgets/task_statistics_card.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/models/task.dart';
import 'task_show_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearchActive = false;
  bool showSearchForm = false;
  bool showStats = false;
  List<Task> filteredTasks = [];
  int selectedTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().loadTasks(refresh: true);
      context.read<TasksProvider>().loadStatistics();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TasksProvider>().loadMoreTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              !showStats ? _buildStatusTabs() : const SizedBox.shrink(),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: showStats ? _buildStatistics() : _buildTasksList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: showStats
          ? IconButton(
              onPressed: () {
                setState(() {
                  showStats = false;
                });
              },
              icon: const Icon(Icons.close, color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.task_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${context.read<TasksProvider>().tasks.length} ${'Assigned Tasks'.tr()}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showSearchForm = !showSearchForm;
                        });
                      },
                      icon: Icon(Icons.search, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showStats = !showStats;
                        });
                      },
                      icon: Icon(Icons.bar_chart, color: Colors.white),
                    ),
                  ],
                ),
                showSearchForm ? _buildSearchBar() : const SizedBox.shrink(),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search tasks...'.tr(),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon: _isSearchActive
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _isSearchActive = false;
                    context.read<TasksProvider>().searchTasks('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _isSearchActive = value.isNotEmpty;
          });
          context.read<TasksProvider>().searchTasks(value);
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<TasksProvider>(
      builder: (context, provider, child) {
        return Container(
            child: SingleChildScrollView(
          child: TaskStatisticsCard(statistics: provider.statistics!),
        ));
      },
    );
  }

  Widget _buildStatusTabs() {
    return Consumer<TasksProvider>(
      builder: (context, provider, child) {
        final statusCounts = provider.taskCountByStatus;
        final statusList = ['All', ...provider.statusList.map((s) => s.name)];

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: statusList.map((status) {
              final count = statusCounts[status] ?? 0;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.tr()),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onTap: (index) {
              setState(() {
                selectedTabIndex = index;
                filteredTasks = selectedTabIndex > 0
                    ? provider.tasks.where((task) {
                        return task.status!.id ==
                            provider.statusList[selectedTabIndex - 1].id;
                      }).toList()
                    : provider.tasks;
              });

              final statusList = [
                'All',
                ...provider.statusList.map((s) => s.id.toString())
              ];
              if (index < statusList.length) {
                // provider.filterByStatus(statusList[index]);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTasksList() {
    return Consumer<TasksProvider>(
      builder: (context, provider, child) {
        filteredTasks = selectedTabIndex > 0
            ? provider.tasks
                .where((task) =>
                    task.status!.id ==
                    provider.statusList[selectedTabIndex - 1].id)
                .toList()
            : provider.tasks;

        if (provider.isLoading && filteredTasks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          );
        }

        if (provider.error != null && filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadTasks(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'.tr()),
                ),
              ],
            ),
          );
        }

        final localFilteredTasks = filteredTasks;

        if (localFilteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks found'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadTasks(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount:
                localFilteredTasks.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= localFilteredTasks.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    ),
                  ),
                );
              }

              final task = localFilteredTasks[index];
              return _buildTaskCard(task);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTaskDetails(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    _buildPriorityBadge(task.priority!),
                  ],
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(task.status!),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: task.isOverdue ? Colors.red : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.timeRemaining,
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: task.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (task.commentsCount > 0) ...[
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.commentsCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (task.team.isNotEmpty) _buildTeamAvatars(task.team),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProgressBar(task),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'Progress'.tr()}: ${task.progressText}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!task.isCompleted)
                      InkWell(
                        onTap: () => _markTaskCompleted(task),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mark Complete'.tr(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    switch (priority.name.toLowerCase()) {
      case 'urgent':
        color = const Color(0xFFEF4444);
        break;
      case 'high':
        color = const Color(0xFFF59E0B);
        break;
      case 'normal':
        color = const Color(0xFF6B7280);
        break;
      case 'low':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.name,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    switch (status.color) {
      case 'success':
        color = const Color(0xFF10B981);
        break;
      case 'warning':
        color = const Color(0xFFF59E0B);
        break;
      case 'info':
        color = const Color(0xFF3B82F6);
        break;
      case 'secondary':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTeamAvatars(List<TaskTeamMember> team) {
    return Row(
      children: team.take(3).map((member) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF667eea),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(Task task) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: task.progress != null ? task.progress! / 100 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: task.isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFF667eea),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskShowPage(task: task),
      ),
    );
  }

  void _markTaskCompleted(Task task) {
    context.read<TasksProvider>().markTaskCompleted(task.id);
  }
}
