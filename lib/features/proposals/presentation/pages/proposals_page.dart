import 'package:flutter/material.dart';
import 'package:medians_ai_crm/features/proposals/presentation/pages/proposal_edit_page.dart';
import 'package:medians_ai_crm/features/proposals/presentation/pages/proposal_show_page.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/proposals_provider.dart';
import '../../../../core/models/proposal.dart';
import '../../../../core/theme/app_colors.dart';

class ProposalsPage extends StatefulWidget {
  const ProposalsPage({super.key});

  @override
  State<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  bool showSearchForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final proposalsProvider =
            Provider.of<ProposalsProvider>(context, listen: false);
        proposalsProvider.loadNextPage();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final proposalsProvider =
          Provider.of<ProposalsProvider>(context, listen: false);
      proposalsProvider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<ProposalsProvider>().loadProposals(refresh: true);
  }

  void _onSearch(String query) {
    context.read<ProposalsProvider>().searchProposals(query);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchAndFilter(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildProposalsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposals'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).tr(),
                Consumer<ProposalsProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      '${'Assigned Proposals'.tr()} ${provider.proposals.length.toString()}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Consumer<ProposalsProvider>(
            builder: (context, provider, child) {
              return provider.isLoading
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => provider.loadProposals(refresh: true),
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 24),
                      ),
                    );
            },
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  showSearchForm = !showSearchForm;
                });
              },
              icon: const Icon(Icons.search, color: Colors.white, size: 24))
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<ProposalsProvider>(builder: (context, provider, child) {
      return !showSearchForm
          ? Text("${'Total Proposals'.tr()} ${provider.proposals.length}",
              style: const TextStyle(color: Colors.white, fontSize: 18))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search proposals...'.tr(),
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.filter_list,
                          color: Colors.white.withValues(alpha: 0.9)),
                      title: Text(
                        'Filter & Sort'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 16),
                      onTap: _showFilterBottomSheet,
                    ),
                  ),
                ],
              ),
            );
    });
  }

  Widget _buildProposalsList() {
    return Consumer<ProposalsProvider>(
      builder: (context, provider, child) {
        if (provider.error != null && provider.proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadProposals(refresh: true),
                  child: Text('Retry'.tr()),
                ),
              ],
            ),
          );
        }

        if (provider.isLoading && provider.proposals.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          );
        }
        if (provider.proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Proposals'.tr(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start creating proposals to manage your business opportunities'
                      .tr(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _navigateToCreateProposal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Create Proposal'.tr()),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount:
                  provider.proposals.length + (provider.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.proposals.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen),
                      ),
                    ),
                  );
                }

                final proposal = provider.proposals[index];
                return _buildProposalCard(proposal);
              },
            ));
      },
    );
  }

  Widget _buildProposalCard(Proposal proposal) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToProposalDetails(proposal),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      proposal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  _buildStatusChip(proposal.status),
                ],
              ),
              const SizedBox(height: 10),
              if (proposal.client?.name != null)
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        proposal.client!.name!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (proposal.dates.date != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      'Created'.tr() + ': ${proposal.dates.formattedCreatedAt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              if (proposal.dates.expiryDate != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color:
                          proposal.dates.isExpired ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Expires: ${proposal.dates.formattedValidUntil}',
                      style: TextStyle(
                        fontSize: 12,
                        color: proposal.dates.isExpired
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: proposal.dates.isExpired
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    proposal.financial.formattedTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.primaryGreen),
                        onPressed: () => _navigateToEditProposal(proposal),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(proposal),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProposalStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status.name.toLowerCase()) {
      case 'draft':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'sent':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case 'accepted':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
      case 'expired':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _navigateToCreateProposal() {
    // TODO: Navigate to create proposal page when it's created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create proposal page coming soon')),
    );
  }

  void _navigateToProposalDetails(Proposal proposal) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProposalShowPage(proposal: proposal),
        ));
  }

  void _navigateToEditProposal(Proposal proposal) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProposalEditPage(proposal: proposal),
        ));
  }

  void _showDeleteConfirmation(Proposal proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Proposal'),
        content: Text('Are you sure you want to delete "${proposal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProposal(proposal.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProposal(int id) async {
    final success = await context.read<ProposalsProvider>().deleteProposal(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal deleted successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ProposalsProvider>().error ??
              'Failed to delete proposal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => __FilterBottomSheetState();
}

class __FilterBottomSheetState extends State<_FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProposalsProvider>(
      builder: (context, provider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.lightGreen],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Proposals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusFilter(provider),
                      const SizedBox(height: 20),
                      _buildQuickFilters(provider),
                      const SizedBox(height: 20),
                      _buildSortingOptions(provider),
                      const SizedBox(height: 30),
                      _buildFilterActions(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter(ProposalsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: provider.statuses.map((status) {
            final isSelected = provider.selectedStatusId == status.id;
            return FilterChip(
              label: Text(status.name),
              selected: isSelected,
              onSelected: (selected) {
                provider.filterByStatus(selected ? status.id : null);
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickFilters(ProposalsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            FilterChip(
              label: Text('Expired'),
              selected: provider.expired == true,
              onSelected: (_) => provider.toggleExpiredFilter(),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
            FilterChip(
              label: Text('Expiring Soon'),
              selected: provider.expiringSoon == true,
              onSelected: (_) => provider.toggleExpiringSoonFilter(),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
            FilterChip(
              label: Text('Converted'),
              selected: provider.convertedToInvoice == true,
              onSelected: (_) => provider.toggleConvertedFilter(),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
            FilterChip(
              label: Text('My Proposals'),
              selected: provider.myProposalsOnly,
              onSelected: (_) => provider.toggleMyProposalsOnly(),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortingOptions(ProposalsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _buildSortChip(provider, 'Created', 'created_at'),
            _buildSortChip(provider, 'Updated', 'updated_at'),
            _buildSortChip(provider, 'Title', 'title'),
            _buildSortChip(provider, 'Total', 'total'),
            _buildSortChip(provider, 'Expiry', 'expiry_date'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Order: '),
            const SizedBox(width: 10),
            FilterChip(
              label: Text('Newest First'),
              selected: provider.sortOrder == 'desc',
              onSelected: (_) => provider.setSorting(provider.sortBy, 'desc'),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: Text('Oldest First'),
              selected: provider.sortOrder == 'asc',
              onSelected: (_) => provider.setSorting(provider.sortBy, 'asc'),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(
      ProposalsProvider provider, String label, String sortBy) {
    final isSelected = provider.sortBy == sortBy;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          provider.setSorting(sortBy, provider.sortOrder);
        }
      },
      selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryGreen,
    );
  }

  Widget _buildFilterActions(ProposalsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              'Apply',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
