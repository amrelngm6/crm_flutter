import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/estimate_requests_provider.dart';
import '../../../../core/models/estimate_request.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../widgets/estimate_request_card.dart';
import '../widgets/estimate_request_statistics_card.dart';

class EstimateRequestsPage extends StatefulWidget {
  const EstimateRequestsPage({super.key});

  @override
  State<EstimateRequestsPage> createState() => _EstimateRequestsPageState();
}

class _EstimateRequestsPageState extends State<EstimateRequestsPage> with TickerProviderStateMixin {
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
        final provider = Provider.of<EstimateRequestsProvider>(context, listen: false);
        if (provider.hasMoreData && !provider.isLoadingMore) {
          provider.loadMoreEstimateRequests();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<EstimateRequestsProvider>(context, listen: false);
    await Future.wait([
      provider.loadEstimateRequests(),
      provider.loadStatistics(),
      provider.loadFormData(),
    ]);
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
    return Consumer<EstimateRequestsProvider>(
      builder: (context, provider, child) {
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
                  _buildAppBar(provider),

                  // Search Section
                  if (showSearchForm) _buildSearchSection(provider),
                  const SizedBox(height: 16),
                  if (!showStats) _buildStatusFilter(provider),

                  // Dashboard Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: showStats
                            ? _buildStatistics(provider)
                            : _buildContentCard(provider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToCreate(),
            backgroundColor: const Color(0xFF1B4D3E),
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New Request'.tr(),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(EstimateRequestsProvider provider) {
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
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
                        'Estimate Requests'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Manage Requests'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
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

  Widget _buildSearchSection(EstimateRequestsProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search requests...'.tr(),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        provider.searchEstimateRequests('');
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
                  provider.searchEstimateRequests(value);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(EstimateRequestsProvider provider) {
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
          child: provider.statistics.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : EstimateRequestStatisticsCard(statistics: provider.statistics),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(EstimateRequestsProvider provider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.statusOptions.length + 1,
        itemBuilder: (context, index) {
          final status = index == 0
              ? EstimateRequestStatus(id: -1, name: 'All')
              : provider.statusOptions[index - 1];
          final isSelected = index == 0 ? _selectedStatus == 'All' : _selectedStatus == status.id.toString();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = index == 0 ? 'All' : status.id.toString();
              });
              provider.filterByStatus(index == 0 ? null : status.id);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.white : Colors.transparent,
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
  }

  Widget _buildContentCard(EstimateRequestsProvider provider) {
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

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: provider.isLoading && provider.estimateRequests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null && provider.estimateRequests.isEmpty
                    ? _buildErrorView(provider)
                    : _buildRequestsList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(EstimateRequestsProvider provider) {
    if (provider.estimateRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshEstimateRequests(),
      color: const Color(0xFF1B4D3E),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.estimateRequests.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.estimateRequests.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final request = provider.estimateRequests[index];
          return EstimateRequestCard(
            request: request,
            onTap: () => _navigateToDetails(request),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(EstimateRequestsProvider provider) {
    return CustomErrorWidget(
      message: provider.error ?? 'Unknown error'.tr(),
      onRetry: () => provider.refreshEstimateRequests(),
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
              Icons.request_quote_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No requests found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No estimate requests found'.tr(),
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

  void _navigateToCreate() {
    context.push('/estimate-requests/create');
  }

  void _navigateToDetails(EstimateRequest request) {
    context.push('/estimate-requests/${request.id}');
  }
}