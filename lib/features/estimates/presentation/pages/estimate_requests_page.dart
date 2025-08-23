import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/estimate_requests_provider.dart';
import '../../../../core/models/estimate_request.dart';
import '../../../../shared/widgets/app_bar_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../widgets/estimate_request_card.dart';
import '../widgets/estimate_request_statistics_card.dart';

class EstimateRequestsPage extends StatefulWidget {
  const EstimateRequestsPage({super.key});

  @override
  State<EstimateRequestsPage> createState() => _EstimateRequestsPageState();
}

class _EstimateRequestsPageState extends State<EstimateRequestsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  bool showSearchForm = false;
  bool showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final provider =
            Provider.of<EstimateRequestsProvider>(context, listen: false);
        provider.loadEstimateRequests();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<EstimateRequestsProvider>(context, listen: false);
      provider.loadEstimateRequests(refresh: true);
      provider.loadStatistics();
      provider.loadFormData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B4D3E),
              Color(0xFF2D6A4F),
              Color(0xFF40916C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              showStats
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          showStats = false;
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    )
                  : _buildAppBar(),
              showSearchForm
                  ? _buildSearchAndFilters()
                  : const SizedBox.shrink(),
              showStats ? const SizedBox.shrink() : _buildTabBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (showStats) ...[
                        const SizedBox(height: 20),
                        Consumer<EstimateRequestsProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoadingStatistics) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return EstimateRequestStatisticsCard(
                              statistics: provider.statistics,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        backgroundColor: const Color(0xFF1B4D3E),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: tr('Create Estimate Request'),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              tr('Estimate Requests'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showStats = !showStats;
              });
            },
            icon: Icon(
              showStats ? Icons.close : Icons.analytics,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showSearchForm = !showSearchForm;
              });
            },
            icon: Icon(
              showSearchForm ? Icons.close : Icons.search,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr('Search estimate requests...'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<EstimateRequestsProvider>().setSearchQuery('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              context.read<EstimateRequestsProvider>().setSearchQuery(value);
            },
          ),
          const SizedBox(height: 16),
          Consumer<EstimateRequestsProvider>(
            builder: (context, provider, child) {
              if (provider.formData == null) {
                return const SizedBox.shrink();
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: tr('Status'),
                    selected: provider.statusFilter != null,
                    onTap: () => _showStatusFilterDialog(provider),
                  ),
                  _buildFilterChip(
                    label: tr('Assigned To'),
                    selected: provider.assignedToFilter != null,
                    onTap: () => _showAssignedToFilterDialog(provider),
                  ),
                  _buildFilterChip(
                    label: tr('Priority'),
                    selected: provider.priorityFilter != null,
                    onTap: () => _showPriorityFilterDialog(provider),
                  ),
                  _buildFilterChip(
                    label: tr('Source'),
                    selected: provider.sourceFilter != null,
                    onTap: () => _showSourceFilterDialog(provider),
                  ),
                  _buildFilterChip(
                    label: tr('Urgent'),
                    selected: provider.urgentFilter == true,
                    onTap: () => provider.setUrgentFilter(
                      provider.urgentFilter == true ? null : true,
                    ),
                  ),
                  _buildFilterChip(
                    label: tr('Follow Up'),
                    selected: provider.followUpFilter == true,
                    onTap: () => provider.setFollowUpFilter(
                      provider.followUpFilter == true ? null : true,
                    ),
                  ),
                  if (provider.statusFilter != null ||
                      provider.assignedToFilter != null ||
                      provider.priorityFilter != null ||
                      provider.sourceFilter != null ||
                      provider.urgentFilter != null ||
                      provider.followUpFilter != null)
                    _buildFilterChip(
                      label: tr('Clear All'),
                      selected: false,
                      onTap: () => provider.clearFilters(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF1B4D3E).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1B4D3E),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1B4D3E) : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF1B4D3E),
        unselectedLabelColor: Colors.white,
        tabs: [
          Tab(text: tr('All')),
          Tab(text: tr('New')),
          Tab(text: tr('In Progress')),
          Tab(text: tr('Completed')),
          Tab(text: tr('Archived')),
        ],
        onTap: (index) {
          _filterByTab(index);
        },
      ),
    );
  }

  void _filterByTab(int index) {
    final provider = context.read<EstimateRequestsProvider>();
    switch (index) {
      case 0: // All
        provider.clearFilters();
        break;
      case 1: // New
        provider.clearFilters();
        // Find "New" status ID from form data
        if (provider.formData != null) {
          final newStatus = provider.formData!.statuses
              .firstWhere((s) => s.name.toLowerCase() == 'new',
                  orElse: () => provider.formData!.statuses.first);
          provider.setStatusFilter(newStatus.id);
        }
        break;
      case 2: // In Progress
        provider.clearFilters();
        // Find "In Progress" status ID from form data
        if (provider.formData != null) {
          final inProgressStatus = provider.formData!.statuses
              .firstWhere((s) => s.name.toLowerCase().contains('progress'),
                  orElse: () => provider.formData!.statuses.first);
          provider.setStatusFilter(inProgressStatus.id);
        }
        break;
      case 3: // Completed
        provider.clearFilters();
        // Find "Completed" status ID from form data
        if (provider.formData != null) {
          final completedStatus = provider.formData!.statuses
              .firstWhere((s) => s.name.toLowerCase().contains('complete'),
                  orElse: () => provider.formData!.statuses.first);
          provider.setStatusFilter(completedStatus.id);
        }
        break;
      case 4: // Archived
        provider.clearFilters();
        // Find "Archived" status ID from form data
        if (provider.formData != null) {
          final archivedStatus = provider.formData!.statuses
              .firstWhere((s) => s.name.toLowerCase().contains('archive'),
                  orElse: () => provider.formData!.statuses.first);
          provider.setStatusFilter(archivedStatus.id);
        }
        break;
    }
  }

  Widget _buildContent() {
    return Consumer<EstimateRequestsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.estimateRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null && provider.estimateRequests.isEmpty) {
          return CustomErrorWidget(
            message: provider.error!,
            onRetry: () => provider.loadEstimateRequests(refresh: true),
          );
        }

        if (provider.estimateRequests.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEstimateRequests(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.estimateRequests.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.estimateRequests.length) {
                if (provider.hasMoreData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final request = provider.estimateRequests[index];
              return EstimateRequestCard(
                request: request,
                onTap: () => _navigateToDetails(request),
                onStatusChange: (statusId) =>
                    provider.changeStatus(request.id, statusId),
                onAssignStaff: (staffId) =>
                    provider.assignStaff(request.id, staffId),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            tr('No estimate requests found'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Create your first estimate request to get started'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add),
            label: Text(tr('Create Request')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(EstimateRequest request) {
    context.push('/estimate-requests/${request.id}');
  }

  void _showCreateDialog() {
    // TODO: Implement create estimate request dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Create Estimate Request')),
        content: Text(tr('Estimate request creation feature will be implemented here')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Close')),
          ),
        ],
      ),
    );
  }

  void _showStatusFilterDialog(EstimateRequestsProvider provider) {
    if (provider.formData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Filter by Status')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.formData!.statuses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(tr('All Statuses')),
                  onTap: () {
                    provider.setStatusFilter(null);
                    Navigator.pop(context);
                  },
                );
              }

              final status = provider.formData!.statuses[index - 1];
              return ListTile(
                title: Text(status.name),
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${status.color.substring(1)}')),
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () {
                  provider.setStatusFilter(status.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAssignedToFilterDialog(EstimateRequestsProvider provider) {
    if (provider.formData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Filter by Assigned To')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.formData!.staffMembers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(tr('All Staff')),
                  onTap: () {
                    provider.setAssignedToFilter(null);
                    Navigator.pop(context);
                  },
                );
              }

              final staff = provider.formData!.staffMembers[index - 1];
              return ListTile(
                title: Text(staff['name'] ?? ''),
                subtitle: Text(staff['email'] ?? ''),
                onTap: () {
                  provider.setAssignedToFilter(staff['id']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPriorityFilterDialog(EstimateRequestsProvider provider) {
    if (provider.formData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Filter by Priority')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.formData!.priorities.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(tr('All Priorities')),
                  onTap: () {
                    provider.setPriorityFilter(null);
                    Navigator.pop(context);
                  },
                );
              }

              final priority = provider.formData!.priorities[index - 1];
              return ListTile(
                title: Text(priority['name'] ?? ''),
                onTap: () {
                  provider.setPriorityFilter(priority['value']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSourceFilterDialog(EstimateRequestsProvider provider) {
    if (provider.formData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Filter by Source')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.formData!.sources.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(tr('All Sources')),
                  onTap: () {
                    provider.setSourceFilter(null);
                    Navigator.pop(context);
                  },
                );
              }

              final source = provider.formData!.sources[index - 1];
              return ListTile(
                title: Text(source['name'] ?? ''),
                onTap: () {
                  provider.setSourceFilter(source['value']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}