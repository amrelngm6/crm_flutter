import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/estimates/presentation/widgets/estimate_statistics_card.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // added import
import '../../../../core/providers/estimates_provider.dart';
import '../../../../core/models/estimate.dart';
import 'estimate_show_page.dart';

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage>
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
        final estimatesProvider =
            Provider.of<EstimatesProvider>(context, listen: false);
        estimatesProvider.loadEstimates();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estimatesProvider =
          Provider.of<EstimatesProvider>(context, listen: false);
      estimatesProvider.loadEstimates(refresh: true);
      estimatesProvider.loadStatistics();
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
                      icon: Icon(Icons.close),
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: showStats
                            ? _buildStatiistics()
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildEstimatesList(),
                                  _buildFilteredEstimatesList('pending'),
                                  _buildFilteredEstimatesList('approved'),
                                  _buildFilteredEstimatesList('rejected'),
                                  _buildConvertedEstimatesList(),
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimates'.tr(), // localized
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${Provider.of<EstimatesProvider>(context).estimates.length} ${'Assigned Estimates'.tr()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search estimates...'.tr(), // localized
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (value) {
                  Provider.of<EstimatesProvider>(context, listen: false)
                      .searchEstimates(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showFilterDialog,
              icon: Icon(Icons.filter_list,
                  color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          )),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding:
            const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        labelColor: const Color(0xFF1B4D3E),
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        tabs: [
          Tab(text: 'All'.tr()),
          Tab(text: 'Pending'.tr()),
          Tab(text: 'Approved'.tr()),
          Tab(text: 'Rejected'.tr()),
          Tab(text: 'Converted'.tr()),
        ],
      ),
    );
  }

  Widget _buildStatiistics() {
    return Consumer<EstimatesProvider>(
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
                    : EstimateStatisticsCard(statistics: provider.statistics!),
              ),
            ));
      },
    );
  }

  Widget _buildEstimatesList() {
    return Consumer<EstimatesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.estimates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.estimates.isEmpty) {
          return _buildErrorView(provider.error!);
        }

        if (provider.estimates.isEmpty) {
          return _buildEmptyView();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEstimates(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                provider.estimates.length + (provider.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.estimates.length) {
                return const Center();
              }

              final estimate = provider.estimates[index];
              return _buildEstimateCard(estimate);
            },
          ),
        );
      },
    );
  }

  Widget _buildFilteredEstimatesList(String approvalStatus) {
    return Consumer<EstimatesProvider>(
      builder: (context, provider, child) {
        final filteredEstimates = provider.estimates.where((estimate) {
          return estimate.approval.status == approvalStatus;
        }).toList();

        if (provider.isLoading && filteredEstimates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredEstimates.isEmpty) {
          return _buildEmptyView('No estimates found'.tr());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEstimates.length,
          itemBuilder: (context, index) {
            final estimate = filteredEstimates[index];
            return _buildEstimateCard(estimate);
          },
        );
      },
    );
  }

  Widget _buildConvertedEstimatesList() {
    return Consumer<EstimatesProvider>(
      builder: (context, provider, child) {
        final convertedEstimates = provider.estimates.where((estimate) {
          return estimate.conversion.isConverted;
        }).toList();

        if (provider.isLoading && convertedEstimates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (convertedEstimates.isEmpty) {
          return _buildEmptyView(
              '${'No'.tr()} ${'converted'.tr()} ${'estimates found'.tr()}');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: convertedEstimates.length,
          itemBuilder: (context, index) {
            final estimate = convertedEstimates[index];
            return _buildEstimateCard(estimate);
          },
        );
      },
    );
  }

  Widget _buildEstimateCard(Estimate estimate) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEstimateDetails(estimate),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estimate.estimateNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estimate.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(estimate.status.color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estimate.status.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(estimate.status.color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estimate.formattedTotal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      estimate.clientName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (estimate.dates.isExpired) ...[
                    Icon(Icons.warning, size: 16, color: Colors.red[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Expired'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (estimate.dates.daysUntilExpiry != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${estimate.dates.daysUntilExpiry!.toInt()} ${'days left'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildApprovalBadge(estimate.approval),
                  const Spacer(),
                  if (estimate.conversion.isConverted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Converted'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${estimate.itemsCount} ${'items'.tr()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(EstimateApproval approval) {
    Color color;
    IconData icon;

    if (approval.isApproved) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (approval.isRejected) {
      color = Colors.red;
      icon = Icons.cancel;
    } else {
      color = Colors.orange;
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            approval.status.tr().toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load estimates'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<EstimatesProvider>(context, listen: false)
                    .loadEstimates(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text('Try Again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView([String? message]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message ?? 'No estimates found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Assigned Estimate requests'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case '#28a745':
      case 'green':
        return Colors.green;
      case '#007bff':
      case 'blue':
        return Colors.blue;
      case '#dc3545':
      case 'red':
        return Colors.red;
      case '#ffc107':
      case 'yellow':
        return Colors.orange;
      case '#17a2b8':
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _navigateToEstimateDetails(Estimate estimate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EstimateShowPage(estimate: estimate),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<EstimatesProvider>(
        builder: (context, provider, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Estimates'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Status'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: provider.statuses.map((status) {
                    final isSelected =
                        provider.selectedStatusId == status.id.toString();
                    return FilterChip(
                      label: Text(status.name.tr()),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.filterByStatus(
                            selected ? status.id.toString() : null);
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor:
                          _getStatusColor(status.color).withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Approval Status'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['pending', 'approved', 'rejected'].map((status) {
                    final isSelected =
                        provider.selectedApprovalStatus == status;
                    return FilterChip(
                      label: Text(status.tr().toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider
                            .filterByApprovalStatus(selected ? status : null);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text('Clear Filters'.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
