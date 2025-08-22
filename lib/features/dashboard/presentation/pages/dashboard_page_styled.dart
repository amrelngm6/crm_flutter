import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/core/models/task.dart';
import 'package:medians_ai_crm/core/models/notification.dart'
    as notification_model;
import 'package:medians_ai_crm/core/providers/notification_provider.dart';
import 'package:medians_ai_crm/features/tasks/presentation/pages/task_show_page.dart';
import 'package:medians_ai_crm/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';

class DashboardPageStyled extends StatefulWidget {
  const DashboardPageStyled({super.key});

  @override
  State<DashboardPageStyled> createState() => _DashboardPageStyledState();
}

class _DashboardPageStyledState extends State<DashboardPageStyled>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
    _loadNotifications();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  // Load notifications
  Future<void> _loadNotifications() async {
    // Avoid calling provider methods during widget build by scheduling
    // the load after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      try {
        await notificationProvider.loadLatestNotifications();
        // Handle notifications data
      } catch (e) {
        // Handle error
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dashboardProvider =
          Provider.of<DashboardProvider>(context, listen: false);

      // Initialize user data if needed
      if (userProvider.currentUser == null) {
        await userProvider.loadUserFromStorage();
      }
      await userProvider.checkAuthStatus();

      // Load dashboard data
      await dashboardProvider.loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<UserProvider, NotificationProvider, DashboardProvider,
        TasksProvider>(
      builder: (context, userProvider, notificationProvider, dashboardProvider,
          tasksProvider, child) {
        return Scaffold(
          drawer: const AppDrawer(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B4D3E), // Dark teal
                  Color(0xFF2D6A4F), // Medium teal
                  Color(0xFF40916C), // Lighter teal
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(notificationProvider),

                  // Dashboard Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Welcome Header
                            _buildWelcomeHeader(userProvider),

                            const SizedBox(height: 40),

                            // Dashboard Content Card - Draggable
                            Expanded(
                              child: _buildDraggableDashboardCard(
                                  dashboardProvider, tasksProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(notificationProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Text(
            'Dashboard'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showNotifications(notificationProvider);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, child) {
                  return GestureDetector(
                    onTap: dashboardProvider.isLoading
                        ? null
                        : () {
                            _refreshDashboard();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dashboardProvider.isLoading
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: dashboardProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(UserProvider userProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[300],
                backgroundImage: userProvider.getUserAvatarUrl().isNotEmpty
                    ? NetworkImage(userProvider.getUserAvatarUrl())
                    : null,
                child: userProvider.getUserAvatarUrl().isEmpty
                    ? Text(
                        userProvider.getUserInitials(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                Text(
                  'Welcome back'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                // User Name
                Text(
                  userProvider.firstName.isNotEmpty
                      ? userProvider.firstName
                      : 'User'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // User Role & Business
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${userProvider.userPosition} • ${userProvider.businessName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Welcome Message
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableDashboardCard(
      DashboardProvider dashboardProvider, TasksProvider tasksProvider) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8, // Start at 80% of available height
      minChildSize: 0.6, // Minimum 20% of available height (more collapsed)
      maxChildSize: 1, // Maximum 100% of available height
      snap: true,
      snapSizes: const [0.6, 0.7, 0.8, 1], // More snap positions
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced Drag Handle
              GestureDetector(
                onTap: () {
                  // Optional: Add haptic feedback or animations
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              // Last updated timestamp
              if (dashboardProvider.lastUpdated != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${'Updated'.tr()} ${_formatTimeAgo(dashboardProvider.lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),

              // Dashboard Content
              Expanded(
                child: dashboardProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dashboardProvider.error != null
                        ? _buildErrorView(dashboardProvider)
                        : _buildDashboardContent(
                            dashboardProvider, tasksProvider, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView(DashboardProvider dashboardProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Failed to load dashboard'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dashboardProvider.error ?? 'Unknown error'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => dashboardProvider.refreshDashboard(),
              icon: const Icon(Icons.refresh),
              label: Text('Try Again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      DashboardProvider dashboardProvider, TasksProvider tasksProvider,
      [ScrollController? scrollController]) {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshDashboard(showSnackbar: false);
      },
      color: const Color(0xFF1B4D3E),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        controller: scrollController, // Use the provided scroll controller
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        dragStartBehavior: DragStartBehavior.start,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            _buildStatsGrid(dashboardProvider),

            const SizedBox(height: 32),

            // Recent Activities Section
            _buildSectionHeader('Recent Activities'.tr(), Icons.history),
            const SizedBox(height: 16),
            _buildActivitiesList(dashboardProvider),

            const SizedBox(height: 32),

            // Today's Tasks Section
            _buildSectionHeader('Today\'s Tasks'.tr(), Icons.task_alt),
            const SizedBox(height: 16),
            Container(
              child: _buildTasksList(dashboardProvider, tasksProvider),
            ),

            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardProvider dashboardProvider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          'Total Clients'.tr(),
          dashboardProvider.totalClients.toString(),
          Icons.people,
          const Color(0xFF52D681),
        ),
        _buildStatCard(
          'Active Leads'.tr(),
          dashboardProvider.activeLeads.toString(),
          Icons.trending_up,
          const Color(0xFF2196F3),
        ),
        _buildStatCard(
          'Today Tasks'.tr(),
          dashboardProvider.todayTasks.toString(),
          Icons.task_alt,
          const Color(0xFFFF9800),
        ),
        _buildStatCard(
          'Meetings'.tr(),
          dashboardProvider.upcomingMeetings.toString(),
          Icons.event,
          const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1B4D3E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(DashboardProvider dashboardProvider) {
    final activities = dashboardProvider.recentActivities;

    if (activities.isEmpty) {
      return _buildEmptyState('No recent activities'.tr(), Icons.history);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 5 ? 5 : activities.length, // Show max 5
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final color = dashboardProvider.getActivityColor(activity.type);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(activity.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksList(
      DashboardProvider dashboardProvider, TasksProvider tasksProvider) {
    final tasks = dashboardProvider.todayTasksList;

    if (tasks.isEmpty) {
      return _buildEmptyState('No tasks for today'.tr(), Icons.task_alt);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length > 3 ? 3 : tasks.length, // Show max 3
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final priorityColor =
            dashboardProvider.getTaskPriorityColor(task.priority);

        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: GestureDetector(
              onTap: () async {
                setState(() {});
                final Task? _task = task.type == 'task'
                    ? await tasksProvider.getTaskById(task.id)
                    : null;
                if (_task != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskShowPage(task: _task),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  // Left colored border indicator
                  Positioned(
                    left: -16,
                    top: -16,
                    bottom: -16,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Task content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${'Due:'.tr()} ${_formatTimeAgo(task.dueDate!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Close the Column widget for task content
                    ],
                  ),
                  // Close the Stack widget
                ],
              ),
            ));
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'.tr(), Icons.bolt),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Leads'.tr(),
                Icons.person_add,
                const Color.fromARGB(255, 20, 108, 87),
                () => context.push('/leads'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Deals'.tr(),
                Icons.business_center,
                const Color(0xFF9b59b6),
                () => context.push('/deals'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Tasks'.tr(),
                Icons.task_alt,
                const Color(0xFF667eea),
                () => context.push('/tasks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Clients'.tr(),
                Icons.business,
                const Color(0xFF2196F3),
                () => context.push('/customers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Estimates'.tr(),
                Icons.description,
                const Color(0xFF1B4D3E),
                () => context.push('/estimates'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Proposals'.tr(),
                Icons.event,
                const Color.fromARGB(255, 39, 146, 176),
                () => context.push('/proposals'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Meetings'.tr(),
                Icons.event,
                const Color(0xFFFF9800),
                () => context.push('/meetings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Chat'.tr(),
                Icons.chat,
                const Color.fromARGB(255, 255, 0, 128),
                () => context.push('/chat'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Todos'.tr(),
                Icons.checklist,
                const Color(0xFF52D681),
                () => context.push('/todos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Tickets'.tr(),
                Icons.support_agent,
                const Color(0xFF52658F),
                () => context.push('/tickets'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
      bool? readStatus, NotificationProvider notificationProvider) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: Text('Retry'.tr()),
                ),
              ],
            ),
          );
        }

        List<notification_model.Notification> notifications;
        if (readStatus == null) {
          notifications = notificationProvider.notifications;
        } else if (readStatus) {
          notifications = notificationProvider.readNotifications;
        } else {
          notifications = notificationProvider.unreadNotifications;
        }

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  readStatus == null
                      ? 'You\'re all caught up!'.tr()
                      : readStatus
                          ? 'No read notifications'.tr()
                          : 'No unread notifications'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Use a local controller so this list can layout correctly inside a
        // constrained modal. shrinkWrap=true makes the ListView measure its
        // height based on children which is safe here because the modal is
        // already height-constrained.
        final ScrollController _innerController = ScrollController();

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            controller: _innerController,
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                // Trigger loading more when the loading tile is shown
                if (!provider.isLoadingMore) {
                  provider.loadNotifications();
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingWidget(),
                  ),
                );
              }

              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(notification_model.Notification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? Colors.white : Colors.teal[50],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: notification_model.Notification.getTypeColor(
                  notification.type),
              child: Icon(
                notification_model.Notification.getTypeIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!notification.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: notification.isRead ? Colors.black87 : Colors.teal[600],
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: notification_model.Notification.getTypeColor(
                            notification.type)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.type.toUpperCase(),
                    style: TextStyle(
                      color: notification_model.Notification.getTypeColor(
                          notification.type),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => () {},
          itemBuilder: (context) => [
            if (!notification.isRead)
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read, size: 16),
                    const SizedBox(width: 8),
                    Text('Mark Read'.tr()),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Delete'.tr(),
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(NotificationProvider notificationProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.notifications),
                    const SizedBox(width: 12),
                    Text(
                      'Latest Unread Notifications'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              notificationProvider.notifications.isNotEmpty
                  ? SizedBox(
                      // Constrain modal height so inner ListView can layout
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildNotificationsList(
                                false, notificationProvider),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now'.tr();
    }
  }

  // Helper method to get activity icon
  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lead_created':
        return Icons.person_add;
      case 'task_assigned':
        return Icons.task_alt;
      case 'client':
        return Icons.business;
      case 'meeting':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  // Refresh dashboard data
  Future<void> _refreshDashboard({bool showSnackbar = true}) async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);

    try {
      await dashboardProvider.refreshDashboard();

      // Show success message only if explicitly requested (for button tap, not pull-to-refresh)
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Dashboard refreshed successfully'.tr()),
              ],
            ),
            backgroundColor: const Color(0xFF52D681),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('${'Failed to refresh'.tr()}: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
