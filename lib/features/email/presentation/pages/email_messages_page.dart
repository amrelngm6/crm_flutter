import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/email_provider.dart';
import '../../../../core/models/email_message.dart';
import '../../../../shared/widgets/app_bar_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../widgets/email_message_card.dart';
import '../widgets/email_folders_sidebar.dart';

class EmailMessagesPage extends StatefulWidget {
  final int accountId;
  
  const EmailMessagesPage({
    super.key,
    required this.accountId,
  });

  @override
  State<EmailMessagesPage> createState() => _EmailMessagesPageState();
}

class _EmailMessagesPageState extends State<EmailMessagesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  bool showSearchForm = false;
  bool showFolders = false;
  String selectedFolder = 'inbox';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final provider =
            Provider.of<EmailProvider>(context, listen: false);
        provider.loadEmailMessages(accountId: widget.accountId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<EmailProvider>(context, listen: false);
      provider.loadEmailMessages(accountId: widget.accountId, refresh: true);
      provider.loadEmailAccounts(); // To get account info
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
              _buildAppBar(),
              showSearchForm ? _buildSearchForm() : const SizedBox.shrink(),
              _buildTabBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (showFolders) ...[
                        EmailFoldersSidebar(
                          selectedFolder: selectedFolder,
                          onFolderSelected: (folder) {
                            setState(() {
                              selectedFolder = folder;
                            });
                            _filterByFolder(folder);
                          },
                        ),
                        const VerticalDivider(width: 1),
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
        onPressed: () => _showComposeDialog(),
        backgroundColor: const Color(0xFF1B4D3E),
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: tr('Compose Email'),
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
            child: Consumer<EmailProvider>(
              builder: (context, provider, child) {
                final account = provider.emailAccounts
                    .firstWhere((a) => a.id == widget.accountId,
                        orElse: () => provider.emailAccounts.first);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (account.name.isNotEmpty)
                      Text(
                        account.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showFolders = !showFolders;
              });
            },
            icon: Icon(
              showFolders ? Icons.folder_open : Icons.folder,
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
          hintText: tr('Search emails...'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<EmailProvider>().setMessagesSearchQuery('');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          context.read<EmailProvider>().setMessagesSearchQuery(value);
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
          Tab(text: tr('All')),
          Tab(text: tr('Unread')),
          Tab(text: tr('Starred')),
          Tab(text: tr('Important')),
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
        provider.clearMessagesFilters();
        break;
      case 1: // Unread
        provider.clearMessagesFilters();
        provider.setMessagesReadFilter(false);
        break;
      case 2: // Starred
        provider.clearMessagesFilters();
        provider.setMessagesFavouriteFilter(true);
        break;
      case 3: // Important
        provider.clearMessagesFilters();
        provider.setMessagesPriorityFilter('high');
        break;
    }
  }

  void _filterByFolder(String folder) {
    final provider = context.read<EmailProvider>();
    provider.setMessagesFolderFilter(folder);
  }

  Widget _buildContent() {
    return Consumer<EmailProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingMessages && provider.emailMessages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null && provider.emailMessages.isEmpty) {
          return CustomErrorWidget(
            message: provider.error!,
            onRetry: () => provider.loadEmailMessages(
              accountId: widget.accountId,
              refresh: true,
            ),
          );
        }

        if (provider.emailMessages.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEmailMessages(
            accountId: widget.accountId,
            refresh: true,
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.emailMessages.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.emailMessages.length) {
                if (provider.messagesHasMoreData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final message = provider.emailMessages[index];
              return EmailMessageCard(
                message: message,
                onTap: () => _navigateToMessageDetails(message),
                onStar: () => _toggleStar(message),
                onRead: () => _toggleRead(message),
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
            tr('No emails found'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Try changing your search criteria or folder selection'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToMessageDetails(EmailMessage message) {
    context.push('/email/messages/${widget.accountId}/message/${message.id}');
  }

  void _toggleStar(EmailMessage message) {
    // TODO: Implement star/unstar functionality
  }

  void _toggleRead(EmailMessage message) {
    // TODO: Implement mark as read/unread functionality
  }

  void _showComposeDialog() {
    // TODO: Implement compose email dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Compose Email')),
        content: Text(tr('Email composition feature will be implemented here')),
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