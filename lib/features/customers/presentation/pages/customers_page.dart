import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/clients_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/client.dart';
import 'client_show_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedStatus;
  bool showSearchForm = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
    _setupScrollListener();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more data when near the bottom
        final clientsProvider =
            Provider.of<ClientsProvider>(context, listen: false);
        if (clientsProvider.hasMoreData && !clientsProvider.isLoadingMore) {
          clientsProvider.loadMoreClients();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);

    // Initialize user data if needed
    if (userProvider.currentUser == null) {
      await userProvider.loadUserFromStorage();
    }
    await userProvider.checkAuthStatus();

    // Load clients data
    await clientsProvider.loadClients();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ClientsProvider>(
      builder: (context, userProvider, clientsProvider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2196F3), // Blue
                  Color(0xFF1976D2), // Darker blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(clientsProvider),
                  _buildHeaderSection(clientsProvider),
                  _buildStatusFilter(clientsProvider),
                  Expanded(
                    child: _buildContentCard(clientsProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ClientsProvider clientsProvider) {
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
          Expanded(
            child: Text(
              'Clients'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              Consumer<ClientsProvider>(
                builder: (context, provider, _) {
                  return GestureDetector(
                    onTap: () => _refreshClients(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: provider.isLoading
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: provider.isLoading
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
                onTap: () {
                  setState(() {
                    showSearchForm = !showSearchForm;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
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

  Widget _buildHeaderSection(ClientsProvider clientsProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Search Bar
        !showSearchForm
            ? Container()
            : Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search clients...'.tr(),
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.white.withValues(alpha: 0.6)),
                            onPressed: () {
                              _searchController.clear();
                              clientsProvider.searchClients('');
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (value == _searchController.text) {
                        clientsProvider.searchClients(value);
                      }
                    });
                  },
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContentCard(ClientsProvider clientsProvider) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Last updated timestamp
          if (clientsProvider.lastUpdated != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Updated'.tr() +
                      ' ${_formatTimeAgo(clientsProvider.lastUpdated!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: clientsProvider.isLoading && clientsProvider.clients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : clientsProvider.error != null &&
                        clientsProvider.clients.isEmpty
                    ? _buildErrorView(clientsProvider)
                    : _buildClientsList(clientsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(ClientsProvider clientsProvider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: clientsProvider.statusOptions.length,
        itemBuilder: (context, index) {
          final status = clientsProvider.statusOptions[index];
          final isSelected = _selectedStatus == status.id.toString() ||
              (status.id.toString() == 'All' && _selectedStatus == null);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus =
                    status.id.toString() == 'All' ? null : status.id.toString();
              });
              clientsProvider.filterByStatus(status.id.toString());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !isSelected
                        ? const Color(0xFF2196F3)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                status.name.tr(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientsList(ClientsProvider clientsProvider) {
    if (clientsProvider.clients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshClients(showSnackbar: false),
      color: const Color(0xFF2196F3),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: clientsProvider.clients.length +
            (clientsProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= clientsProvider.clients.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final client = clientsProvider.clients[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientShowPage(client: client),
                ),
              );
            },
            child: _buildClientCard(client, clientsProvider),
          );
        },
      ),
    );
  }

  Widget _buildClientCard(Client client, ClientsProvider clientsProvider) {
    final statusColor = clientsProvider.getStatusColor(client.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  clientsProvider.getStatusIcon(client.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  client.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Company and Revenue
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.company ?? 'No company'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Revenue'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    clientsProvider.formatCurrency(client.totalInvoiced),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer with stats
          Row(
            children: [
              Icon(Icons.work, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${client.projectsCount ?? 0} ' + 'projects'.tr(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.receipt, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${client.invoicesCount ?? 0} ' + 'invoices'.tr(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                clientsProvider.formatTimeAgo(client.updatedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ClientsProvider clientsProvider) {
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
              'Something went wrong'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              clientsProvider.error ?? 'Unknown error occurred'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => clientsProvider.loadClients(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: Text('Try Again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No clients found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first client'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddClientDialog,
              icon: const Icon(Icons.add),
              label: Text('Add Client'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Future<void> _refreshClients({bool showSnackbar = true}) async {
    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);

    try {
      await clientsProvider.refreshClients();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Clients refreshed successfully'.tr()),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to refresh'.tr() + ': ${e.toString()}'),
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

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Client'.tr()),
          content: Text('Add client functionality will be implemented'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'.tr()),
            ),
          ],
        );
      },
    );
  }

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
}
