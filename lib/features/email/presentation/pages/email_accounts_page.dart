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

class EmailAccountsPage extends StatefulWidget {
  const EmailAccountsPage({super.key});

  @override
  State<EmailAccountsPage> createState() => _EmailAccountsPageState();
}

class _EmailAccountsPageState extends State<EmailAccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmailProvider>().loadEmailAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: tr('Email Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EmailProvider>().loadEmailAccounts(),
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading && emailProvider.emailAccounts.isEmpty) {
            return LoadingWidget(message: tr('Loading emails'));
          }

          if (emailProvider.error != null && emailProvider.emailAccounts.isEmpty) {
            return CustomErrorWidget(
              message: emailProvider.error!,
              onRetry: () => emailProvider.loadEmailAccounts(),
            );
          }

          if (emailProvider.emailAccounts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => emailProvider.loadEmailAccounts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emailProvider.emailAccounts.length,
              itemBuilder: (context, index) {
                final account = emailProvider.emailAccounts[index];
                return EmailAccountCard(
                  account: account,
                  onTap: () => _navigateToMessages(account),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(),
        child: const Icon(Icons.add),
        tooltip: tr('Add Account'),
      ),
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
            tr('Add an email account to get started'),
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
          ),
        ],
      ),
    );
  }

  void _navigateToMessages(EmailAccount account) {
    context.push('/email/messages/${account.id}');
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Add Account')),
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
