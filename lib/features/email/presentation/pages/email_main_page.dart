import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/email_provider.dart';
import '../../../../core/models/email_account.dart';
import '../../../../shared/widgets/app_bar_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../widgets/email_account_card.dart';

class EmailMainPage extends StatefulWidget {
  const EmailMainPage({super.key});

  @override
  State<EmailMainPage> createState() => _EmailMainPageState();
}

class _EmailMainPageState extends State<EmailMainPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  bool showSearchForm = false;
  bool showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final provider =
            Provider.of<EmailProvider>(context, listen: false);
        provider.loadEmailAccounts();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<EmailProvider>(context, listen: false);
      provider.loadEmailAccounts(refresh: true);
      provider.loadAccountStatistics();
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
                  ? _buildSearchForm()
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
                        Consumer<EmailProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return _buildStatisticsCards(provider.accountStatistics);
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
        onPressed: () => _showAddAccountDialog(),
        backgroundColor: const Color(0xFF1B4D3E),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: tr('Add Email Account'),
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
              tr('Email Management'),
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

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: tr('Search email accounts...'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<EmailProvider>().setAccountsSearchQuery('');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          context.read<EmailProvider>().setAccountsSearchQuery(value);
        },
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
          Tab(text: tr('All Accounts')),
          Tab(text: tr('Active')),
          Tab(text: tr('Inactive')),
        ],
        onTap: (index) {
          _filterByTab(index);
        },
      ),
    );
  }

  void _filterByTab(int index) {
    final provider = context.read<EmailProvider>();
    switch (index) {
      case 0: // All
        provider.clearAccountsFilters();
        break;
      case 1: // Active
        provider.clearAccountsFilters();
        // TODO: Implement active filter
        break;
      case 2: // Inactive
        provider.clearAccountsFilters();
        // TODO: Implement inactive filter
        break;
    }
  }

  Widget _buildStatisticsCards(Map<String, dynamic> statistics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: tr('Total Accounts'),
              value: '${statistics['total_accounts'] ?? 0}',
              icon: Icons.email,
              color: const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: tr('Connected'),
              value: '${statistics['connected_accounts'] ?? 0}',
              icon: Icons.check_circle,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: tr('Total Messages'),
              value: '${statistics['total_messages'] ?? 0}',
              icon: Icons.message,
              color: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<EmailProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.emailAccounts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null && provider.emailAccounts.isEmpty) {
          return CustomErrorWidget(
            message: provider.error!,
            onRetry: () => provider.loadEmailAccounts(refresh: true),
          );
        }

        if (provider.emailAccounts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEmailAccounts(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.emailAccounts.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.emailAccounts.length) {
                if (provider.accountsHasMoreData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final account = provider.emailAccounts[index];
              return EmailAccountCard(
                account: account,
                onTap: () => _navigateToMessages(account),
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
            Icons.email_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            tr('No email accounts found'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Add your first email account to get started'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAccountDialog(),
            icon: const Icon(Icons.add),
            label: Text(tr('Add Account')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMessages(EmailAccount account) {
    context.push('/email/messages/${account.id}');
  }

  void _showAddAccountDialog() {
    // TODO: Implement add email account dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Add Email Account')),
        content: Text(tr('Email account creation feature will be implemented here')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Close')),
          ),
        ],
      ),
    );
  }
}