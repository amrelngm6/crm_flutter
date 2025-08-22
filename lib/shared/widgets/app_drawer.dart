import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with user profile
          _buildDrawerHeader(context),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuSection(
                  'Main Menu',
                  [
                    _DrawerMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/dashboard',
                      color: const Color(0xFF1B4D3E),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.trending_up,
                      title: 'Leads',
                      route: '/leads',
                      color: const Color.fromARGB(255, 20, 108, 87),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.business_center,
                      title: 'Deals',
                      route: '/deals',
                      color: const Color(0xFF9b59b6),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.business,
                      title: 'Clients',
                      route: '/customers',
                      color: const Color(0xFF2196F3),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.task_alt,
                      title: 'Tasks',
                      route: '/tasks',
                      color: const Color(0xFF667eea),
                    ),
                  ],
                ),
                _buildMenuSection(
                  'Sales & Business',
                  [
                    _DrawerMenuItem(
                      icon: Icons.description,
                      title: 'Estimates',
                      route: '/estimates',
                      color: const Color(0xFF1B4D3E),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.article,
                      title: 'Proposals',
                      route: '/proposals',
                      color: const Color.fromARGB(255, 39, 146, 176),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.event,
                      title: 'Meetings',
                      route: '/meetings',
                      color: const Color(0xFFFF9800),
                    ),
                  ],
                ),
                _buildMenuSection(
                  'Communication',
                  [
                    _DrawerMenuItem(
                      icon: Icons.chat,
                      title: 'Chat',
                      route: '/chat',
                      color: const Color.fromARGB(255, 255, 0, 128),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.support_agent,
                      title: 'Tickets',
                      route: '/tickets',
                      color: const Color(0xFF52658F),
                    ),
                  ],
                ),
                _buildMenuSection(
                  'Productivity',
                  [
                    _DrawerMenuItem(
                      icon: Icons.checklist,
                      title: 'Todos',
                      route: '/todos',
                      color: const Color(0xFF52D681),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.notifications_active,
                      title: 'Notifications',
                      route: '/notifications',
                      color: const Color(0xFF1B4D3E),
                    ),
                  ],
                ),
                Divider(height: 32, color: Colors.grey[300]),
                _buildMenuSection(
                  'Account',
                  [
                    _DrawerMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      route: '/profile',
                      color: const Color(0xFF607D8B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer with logout
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B4D3E),
                Color(0xFF2D6A4F),
                Color(0xFF40916C),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // User profile section
                  Row(
                    children: [
                      // Profile avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: userProvider
                                  .getUserAvatarUrl()
                                  .isNotEmpty
                              ? NetworkImage(userProvider.getUserAvatarUrl())
                              : null,
                          child: userProvider.getUserAvatarUrl().isEmpty
                              ? Text(
                                  userProvider.getUserInitials(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.userName.isNotEmpty
                                  ? userProvider.userName
                                  : 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userProvider.userPosition.isNotEmpty
                                  ? userProvider.userPosition
                                  : 'Position',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProvider.businessName.isNotEmpty
                                  ? userProvider.businessName
                                  : 'Company',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<_DrawerMenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.tr(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(item)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(_DrawerMenuItem item) {
    return Builder(
      builder: (context) {
        // Get current route to highlight active item
        final currentRoute = GoRouterState.of(context).uri.toString();
        final isActive = currentRoute == item.route ||
            (item.route == '/dashboard' && currentRoute == '/');

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? item.color.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isActive ? item.color : item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: isActive ? Colors.white : item.color,
                size: 20,
              ),
            ),
            title: Text(
              item.title.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? item.color : Colors.grey[800],
              ),
            ),
            trailing: isActive
                ? Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: item.color,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              context.push(item.route);
            },
          ),
        );
      },
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // App version info
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Medians AI CRM v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(
                Icons.logout,
                size: 18,
              ),
              label: Text('Logout'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B4D3E),
                side: const BorderSide(color: Color(0xFF1B4D3E)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Logout'.tr()),
          content: Text('Are you sure you want to logout?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close drawer

                // Perform logout
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                await userProvider.logout();

                // Navigate to login
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Logout'.tr()),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.color,
  });
}
