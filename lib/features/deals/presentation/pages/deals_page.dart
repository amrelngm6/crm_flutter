import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/deals/presentation/widgets/deal_statistics_card.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/deals_provider.dart';
import '../../../../core/models/deal.dart';
import 'deal_show_page.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool showSearchForm = false;
  bool showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DealsProvider>(context, listen: false);
      provider.loadDeals(refresh: true);
      provider.loadStatistics();
      provider.loadPipelines();
      provider.loadPipelineStages();
    });

    // Setup pagination scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = Provider.of<DealsProvider>(context, listen: false);
        provider.loadMoreDeals();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
          child: showStats
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                      _buildHeader(),
                      Expanded(child: _buildStatistics()),
                    ])
              : Column(
                  children: [
                    _buildHeader(),
                    showSearchForm
                        ? _buildSearchAndFilters()
                        : const SizedBox.shrink(),
                    _buildStatusTabs(),
                    Expanded(
                      child: _buildDealsList(),
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
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deals'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${Provider.of<DealsProvider>(context).deals.length} ${'Assigned Deals'.tr()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
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
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search deals...'.tr(),
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (value) {
                  context.read<DealsProvider>().searchDeals(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              onPressed: () => _showPipelineFilter(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<DealsProvider>(
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
                  : DealStatisticsCard(statistics: provider.statistics!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          final provider = context.read<DealsProvider>();
          setState(() {
            showStats = false;
          });
          switch (index) {
            case 0:
              provider.filterByStatus(null);
              break;
            case 1:
              provider.filterByStatus('0');
              break;
            case 2:
              provider.filterByStatus('won');
              break;
            case 3:
              provider.filterByStatus('lose');
              break;
          }
        },
        tabs: [
          Tab(text: 'All'.tr()),
          Tab(text: 'Pending'.tr()),
          Tab(text: 'Won'.tr()),
          Tab(text: 'Lost'.tr()),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Consumer<DealsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deals.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            );
          }

          if (provider.hasError && provider.deals.isEmpty) {
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
                    'Failed to load deals'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadDeals(refresh: true),
                    child: Text('Retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (provider.deals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deals found'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by creating your first deal'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: provider.deals.length + (provider.hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.deals.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final deal = provider.deals[index];
              return _buildDealCard(deal);
            },
          );
        },
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealShowPage(dealId: deal.id),
            ),
          );
        },
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
                          deal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deal.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    deal.amount.formatted,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2ecc71),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                deal.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Client or Lead info
                  if (deal.client != null || deal.lead != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF667eea),
                      child: Text(
                        (deal.client?.name ?? deal.lead?.name ?? 'U')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deal.client?.name ?? deal.lead?.name ?? 'Unknown'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  // Stage badge
                  if (deal.stage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _parseColor(deal.stage!.color)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _parseColor(deal.stage!.color)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        deal.stage!.name ?? 'Unknown'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _parseColor(deal.stage!.color),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Probability'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${deal.probability.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: deal.probability / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProbabilityColor(deal.probability),
                    ),
                  ),
                ],
              ),
              if (deal.expectedDueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${"Due".tr()}: ${_formatDate(deal.expectedDueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPipelineFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<DealsProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Pipeline'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.pipelines.isEmpty) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    ListTile(
                      title: Text('All Pipelines'.tr()),
                      leading: Radio<int?>(
                        value: null,
                        groupValue: provider.selectedPipelineId,
                        onChanged: (value) {
                          provider.filterByPipeline(null);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ...provider.pipelines.map((pipeline) {
                      return ListTile(
                        title: Text(pipeline['name'] ?? 'Unknown'.tr()),
                        leading: Radio<int?>(
                          value: pipeline['id'],
                          groupValue: provider.selectedPipelineId,
                          onChanged: (value) {
                            provider.filterByPipeline(value);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6c757d);
    }
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 80) return const Color(0xFF2ecc71);
    if (probability >= 60) return const Color(0xFFf39c12);
    if (probability >= 40) return const Color(0xFF3498db);
    return const Color(0xFFe74c3c);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
