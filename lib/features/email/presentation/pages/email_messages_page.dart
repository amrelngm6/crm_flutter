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

class EmailMessagesPage extends StatefulWidget {
  final int accountId;

  const EmailMessagesPage({
    super.key,
    required this.accountId,
  });

  @override
  State<EmailMessagesPage> createState() => _EmailMessagesPageState();
}

class _EmailMessagesPageState extends State<EmailMessagesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedFolder = 'All';
  bool? _readFilter;
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
        final emailProvider = Provider.of<EmailProvider>(context, listen: false);
        if (emailProvider.messagesHasMoreData && !emailProvider.isLoadingMessages) {
          emailProvider.loadMoreEmailMessages();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    await emailProvider.loadEmailMessages(accountId: widget.accountId);
    await emailProvider.loadEmailMessageStatistics();
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
    return Consumer<EmailProvider>(
      builder: (context, emailProvider, child) {
        final account = emailProvider.emailAccounts
            .where((a) => a.id == widget.accountId)
            .firstOrNull;

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
                  _buildAppBar(emailProvider, account?.name ?? 'Messages'),

                  // Search Section
                  if (showSearchForm) _buildSearchSection(emailProvider),
                  const SizedBox(height: 16),

                  // Filter Section
                  _buildFilterSection(emailProvider),

                  // Dashboard Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildContentCard(emailProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToCompose(),
            backgroundColor: const Color(0xFF1B4D3E),
            child: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Compose Email'.tr(),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(EmailProvider emailProvider, String accountName) {
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Email Messages'.tr(),
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
                onPressed: () => emailProvider.loadEmailMessages(accountId: widget.accountId),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(EmailProvider emailProvider) {
    return Container(
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
          hintText: 'Search messages...'.tr(),
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
                    emailProvider.searchEmailMessages('');
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
              emailProvider.searchEmailMessages(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildFilterSection(EmailProvider emailProvider) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', _selectedFolder == 'All', () {
            setState(() => _selectedFolder = 'All');
            emailProvider.filterEmailMessages(folder: null);
          }),
          _buildFilterChip('Inbox', _selectedFolder == 'Inbox', () {
            setState(() => _selectedFolder = 'Inbox');
            emailProvider.filterEmailMessages(folder: 'Inbox');
          }),
          _buildFilterChip('Sent', _selectedFolder == 'Sent', () {
            setState(() => _selectedFolder = 'Sent');
            emailProvider.filterEmailMessages(folder: 'Sent');
          }),
          _buildFilterChip('Drafts', _selectedFolder == 'Drafts', () {
            setState(() => _selectedFolder = 'Drafts');
            emailProvider.filterEmailMessages(folder: 'Drafts');
          }),
          _buildFilterChip('Unread', _readFilter == false, () {
            setState(() => _readFilter = _readFilter == false ? null : false);
            emailProvider.filterEmailMessages(isRead: _readFilter);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
          label.tr(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400]!,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(EmailProvider emailProvider) {
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
            child: emailProvider.isLoadingMessages && emailProvider.emailMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : emailProvider.error != null && emailProvider.emailMessages.isEmpty
                    ? _buildErrorView(emailProvider)
                    : _buildMessagesList(emailProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(EmailProvider emailProvider) {
    if (emailProvider.emailMessages.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => emailProvider.loadEmailMessages(accountId: widget.accountId),
      color: const Color(0xFF1B4D3E),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: emailProvider.emailMessages.length + 
                   (emailProvider.isLoadingMessages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= emailProvider.emailMessages.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final message = emailProvider.emailMessages[index];
          return EmailMessageCard(
            message: message,
            onTap: () => _navigateToMessageDetail(message),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(EmailProvider emailProvider) {
    return CustomErrorWidget(
      message: emailProvider.error ?? 'Unknown error'.tr(),
      onRetry: () => emailProvider.loadEmailMessages(accountId: widget.accountId),
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
              Icons.email_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages found'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No email messages in this folder'.tr(),
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

  void _navigateToCompose() {
    context.push('/email/compose/${widget.accountId}');
  }

  void _navigateToMessageDetail(EmailMessage message) {
    context.push('/email/messages/${widget.accountId}/message/${message.id}');
  }
}