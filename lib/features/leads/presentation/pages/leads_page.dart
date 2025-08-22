import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/core/models/status.dart';
import 'package:medians_ai_crm/features/leads/presentation/widgets/lead_statistics_card.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/leads_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/lead.dart';
import 'lead_show_page.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedStatus = 'All';
  bool showSearchForm = false;
  bool showStats = false;

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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more data when near the bottom
        final leadsProvider =
            Provider.of<LeadsProvider>(context, listen: false);
        if (leadsProvider.hasMoreData && !leadsProvider.isLoadingMore) {
          leadsProvider.loadMoreLeads();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);

    // Initialize user data if needed
    if (userProvider.currentUser == null) {
      await userProvider.loadUserFromStorage();
    }
    await userProvider.checkAuthStatus();

    // Load leads data
    await leadsProvider.loadLeads();

    // Load statistics
    await leadsProvider.loadStatistics();
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
    return Consumer2<UserProvider, LeadsProvider>(
      builder: (context, userProvider, leadsProvider, child) {
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
                  _buildAppBar(leadsProvider),

                  // Search Section
                  showSearchForm
                      ? _buildSearchSection(leadsProvider)
                      : Container(),
                  const SizedBox(height: 16),
                  showStats ? Container() : _buildStatusFilter(leadsProvider),
                  // Dashboard Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: showStats
                            ? _buildStatistics()
                            : Column(
                                children: [
                                  // Content Card
                                  Expanded(
                                    child: _buildContentCard(leadsProvider),
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

  Widget _buildAppBar(LeadsProvider leadsProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: showStats
          ? IconButton(
              alignment: Alignment.centerRight,
              onPressed: () {
                setState(() {
                  showStats = false;
                  showSearchForm = false;
                });
              },
              icon: Icon(Icons.close, color: Colors.white, size: 24),
            )
          : Row(
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
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (showStats ? 'Leads Statistics' : 'Leads').tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    showStats
                        ? Container()
                        : Text(
                            'Assigned Leads'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          )
                  ],
                )),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showSearchForm = !showSearchForm;
                        });
                      },
                      icon: const Icon(Icons.search, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showStats = !showStats;
                        });
                      },
                      icon: const Icon(Icons.bar_chart, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSearchSection(LeadsProvider leadsProvider) {
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
                    hintText: 'Search leads...'.tr(),
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              leadsProvider.searchLeads('');
                            },
                            child: Icon(
                              Icons.clear,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        leadsProvider.searchLeads(value);
                      }
                    });
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Consumer<LeadsProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;
        if (stats == null) return const SizedBox.shrink();

        return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: provider.statistics!.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : LeadStatisticsCard(statistics: provider.statistics!),
              ),
            ));
      },
    );
  }

  Widget _buildContentCard(LeadsProvider leadsProvider) {
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

          // Status Filter

          // Last updated timestamp
          if (leadsProvider.lastUpdated != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${'Updated'.tr()} ${_formatTimeAgo(leadsProvider.lastUpdated!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],

          // Content
          Expanded(
            child: leadsProvider.isLoading && leadsProvider.leads.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : leadsProvider.error != null && leadsProvider.leads.isEmpty
                    ? _buildErrorView(leadsProvider)
                    : _buildLeadsList(leadsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(LeadsProvider leadsProvider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: leadsProvider.statusOptions.length + 1,
        itemBuilder: (context, index) {
          final status = index == 0
              ? Status(id: -1, name: 'All', color: 'primary')
              : leadsProvider.statusOptions[index - 1];
          final isSelected =
              (index == 0) || (_selectedStatus == status.id.toString());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus =
                    status.id.toString() == 'All' ? null : status.id.toString();
              });
              leadsProvider.filterByStatus(_selectedStatus?.toLowerCase());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !isSelected ? Colors.transparent : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                status.name.tr(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400]!,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );

    /*
    return Consumer<LeadsProvider>(
      builder: (context, provider, child) {
        final statusCounts = provider.statusOptions.length;
        final statusList = ['All', ...provider.statusOptions.map((s) => s.name)];

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
                    Text(status),
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
*/
  }

  Widget _buildLeadsList(LeadsProvider leadsProvider) {
    if (leadsProvider.leads.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshLeads(showSnackbar: false),
      color: const Color(0xFF1B4D3E),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount:
            leadsProvider.leads.length + (leadsProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= leadsProvider.leads.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final lead = leadsProvider.leads[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadShowPage(lead: lead),
                ),
              );
            },
            child: _buildLeadCard(lead, leadsProvider),
          );
        },
      ),
    );
  }

  Widget _buildLeadCard(Lead lead, LeadsProvider leadsProvider) {
    final statusColor = leadsProvider.getStatusColor(lead.status);

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
                  leadsProvider.getStatusIcon(lead.status),
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
                      lead.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.email,
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
                  lead.status.toUpperCase(),
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

          // Company and Value
          Row(
            children: [
              if (lead.company != null) ...[
                Icon(
                  Icons.business,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  lead.company!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
              ],
              if (lead.value != null) ...[
                const Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  leadsProvider.formatCurrency(lead.value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),

          if (lead.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              lead.notes!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Text(
                'Created ${_formatTimeAgo(lead.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (lead.followUpDate != null) ...[
                const Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Follow up ${_formatTimeAgo(lead.followUpDate!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(LeadsProvider leadsProvider) {
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
              'Failed to load leads'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              leadsProvider.error ?? 'Unknown error'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => leadsProvider.refreshLeads(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No leads found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No assigned leads found'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Future<void> _refreshLeads({bool showSnackbar = true}) async {
    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);

    try {
      await leadsProvider.refreshLeads();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Leads refreshed successfully'.tr()),
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
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to refresh: ${e.toString()}'),
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

  void _showAddLeadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Lead'.tr()),
          content: Text('Add lead functionality will be implemented'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
