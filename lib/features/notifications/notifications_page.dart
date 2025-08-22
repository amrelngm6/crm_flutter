import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification.dart' as notification_model;
import '../../shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<int> _selectedNotifications = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);

    // Load notifications when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
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
                _buildAppBar(),
                TabBar(
                  padding: EdgeInsets.symmetric(horizontal: 25.0),
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Unread'),
                    Tab(text: 'Read'),
                  ],
                ),

                // Profile Section
                Expanded(
                  child: Column(
                    children: [
                      // Settings Options Card
                      Expanded(child: _buildTabsView()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
              child: Text(
            'Notifications list',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          )),
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedNotifications.isNotEmpty ? _bulkDelete : null,
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
              tooltip: 'Cancel',
            ),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, size: 20),
                      SizedBox(width: 8),
                      Text('Mark All Read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _buildTabsView() {
    return DraggableScrollableSheet(
      initialChildSize: 1, // Start at 100% of available height
      minChildSize: 0.6, // Minimum 20% of available height (more collapsed)
      maxChildSize: 1, // Maximum 100% of available height
      snap: true,
      snapSizes: const [0.6, 0.7, 0.8, 1], // More snap positions
      expand: false,
      builder: (context, scrollController) {
        return Container(
            padding: EdgeInsets.only(top: 20),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(null),
                _buildNotificationsList(false), // Unread only
                _buildNotificationsList(true), // Read only
              ],
            ));
      },
    );
  }

  Widget _buildNotificationsList(bool? readStatus) {
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
                  'Error loading notifications',
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<notification_model.Notification> notifications;
        if (readStatus == null) {
          notifications = provider.notifications;
        } else if (readStatus) {
          notifications = provider.readNotifications;
        } else {
          notifications = provider.unreadNotifications;
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
                  'No notifications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  readStatus == null
                      ? 'You\'re all caught up!'
                      : readStatus
                          ? 'No read notifications'
                          : 'No unread notifications',
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
          onRefresh: provider.refresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: const LoadingWidget(),
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
    final isSelected = _selectedNotifications.contains(notification.id);

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
        trailing: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (selected) => _toggleSelection(notification.id),
              )
            : PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleNotificationAction(action, notification),
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 16),
                          SizedBox(width: 8),
                          Text('Mark Read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _enterSelectionMode(notification.id),
      ),
    );
  }

  void _handleNotificationTap(notification_model.Notification notification) {
    if (_isSelectionMode) {
      _toggleSelection(notification.id);
      return;
    }

    // Mark as read if unread
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    // Handle navigation based on notification type and action data
    if (notification.actionData != null) {
      final actionData = notification.actionData!;
      if (actionData.containsKey('route')) {
        context.push(actionData['route']);
      }
    }
  }

  void _handleNotificationAction(
      String action, notification_model.Notification notification) {
    switch (action) {
      case 'mark_read':
        context.read<NotificationProvider>().markAsRead(notification.id);
        break;
      case 'delete':
        _showDeleteConfirmation([notification.id]);
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        context.read<NotificationProvider>().markAllAsRead();
        break;
      case 'refresh':
        context.read<NotificationProvider>().refresh();
        break;
      case 'filters':
        _showFilters();
        break;
    }
  }

  void _enterSelectionMode(int notificationId) {
    setState(() {
      _isSelectionMode = true;
      _selectedNotifications = [notificationId];
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotifications.clear();
    });
  }

  void _toggleSelection(int notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
        if (_selectedNotifications.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  void _selectAll() {
    final provider = context.read<NotificationProvider>();
    setState(() {
      _selectedNotifications = provider.notifications.map((n) => n.id).toList();
    });
  }

  void _bulkDelete() {
    _showDeleteConfirmation(_selectedNotifications);
  }

  void _showDeleteConfirmation(List<int> notificationIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
          notificationIds.length == 1
              ? 'Are you sure you want to delete this notification?'
              : 'Are you sure you want to delete ${notificationIds.length} notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (notificationIds.length == 1) {
                context
                    .read<NotificationProvider>()
                    .deleteNotification(notificationIds.first);
              } else {
                context
                    .read<NotificationProvider>()
                    .bulkDelete(notificationIds);
              }
              _exitSelectionMode();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    // TODO: Implement filters dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters coming soon!')),
    );
  }
}
