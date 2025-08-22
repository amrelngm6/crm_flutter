import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/deals_provider.dart';
import '../../../../../core/models/deal.dart';

class DealShowPage extends StatefulWidget {
  final int dealId;

  const DealShowPage({
    super.key,
    required this.dealId,
  });

  @override
  State<DealShowPage> createState() => _DealShowPageState();
}

class _DealShowPageState extends State<DealShowPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Deal? _deal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeal();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDeal() {
    // Find the deal in the provider's deals list
    final provider = Provider.of<DealsProvider>(context, listen: false);
    _deal = provider.deals.firstWhere(
      (deal) => deal.id == widget.dealId,
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_deal == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Deal Not Found'.tr()),
        ),
        body: Center(
          child: Text('Deal not found'.tr()),
        ),
      );
    }

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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildDetailsTab(),
                            _buildActivityTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deal!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _deal!.code,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      // TODO: Navigate to edit deal
                      break;
                    case 'delete':
                      _showDeleteConfirmation();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('Edit Deal'.tr()),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Deal'.tr(),
                          style: const TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Deal Value'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deal!.amount.formatted,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Probability'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_deal!.probability.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF667eea),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: 'Overview'.tr()),
          Tab(text: 'Details'.tr()),
          Tab(text: 'Activity'.tr()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Description', _deal!.description),
          const SizedBox(height: 20),
          if (_deal!.stage != null) ...[
            _buildStageSection(),
            const SizedBox(height: 20),
          ],
          if (_deal!.client != null || _deal!.lead != null) ...[
            _buildContactSection(),
            const SizedBox(height: 20),
          ],
          if (_deal!.expectedDueDate != null) ...[
            _buildInfoSection(
                'Expected Close Date', _formatDate(_deal!.expectedDueDate!)),
            const SizedBox(height: 20),
          ],
          if (_deal!.team.isNotEmpty) ...[
            _buildTeamSection(),
            const SizedBox(height: 20),
          ],
          if (_deal!.tasks != null) ...[
            _buildTasksSection(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Status', _deal!.status.toUpperCase()),
          const SizedBox(height: 20),
          if (_deal!.contactInfo.email != null ||
              _deal!.contactInfo.phone != null) ...[
            Text(
              'Contact Information'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
            const SizedBox(height: 12),
            if (_deal!.contactInfo.email != null) ...[
              _buildContactRow(Icons.email, 'Email', _deal!.contactInfo.email!),
              const SizedBox(height: 8),
            ],
            if (_deal!.contactInfo.phone != null) ...[
              _buildContactRow(Icons.phone, 'Phone', _deal!.contactInfo.phone!),
              const SizedBox(height: 20),
            ],
          ],
          if (_deal!.locationInfo != null) ...[
            _buildLocationSection(),
            const SizedBox(height: 20),
          ],
          _buildInfoSection('Created', _formatDateTime(_deal!.createdAt)),
          const SizedBox(height: 12),
          _buildInfoSection('Last Updated', _formatDateTime(_deal!.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital Activity'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Website Visits',
                  '${_deal!.digitalActivity.recentVisitsCount}',
                  Icons.visibility,
                  const Color(0xFF3498db),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'Form Submissions'.tr(),
                  '${_deal!.digitalActivity.recentSubmissionsCount}',
                  Icons.assignment,
                  const Color(0xFF2ecc71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _deal!.digitalActivity.hasActivity
                  ? const Color(0xFF2ecc71).withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _deal!.digitalActivity.hasActivity
                    ? const Color(0xFF2ecc71).withValues(alpha: 0.3)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _deal!.digitalActivity.hasActivity
                      ? Icons.check_circle
                      : Icons.info,
                  color: _deal!.digitalActivity.hasActivity
                      ? const Color(0xFF2ecc71)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _deal!.digitalActivity.hasActivity
                        ? 'This deal has recent digital activity'.tr()
                        : 'No recent digital activity'.tr(),
                    style: TextStyle(
                      color: _deal!.digitalActivity.hasActivity
                          ? const Color(0xFF2ecc71)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2c3e50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Stage'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _parseColor(_deal!.stage!.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _parseColor(_deal!.stage!.color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(_deal!.stage!.color),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deal!.stage!.name ?? 'Unknown Stage'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _parseColor(_deal!.stage!.color),
                      ),
                    ),
                    if (_deal!.stage!.pipeline?.name != null) ...[
                      Text(
                        _deal!.stage!.pipeline!.name!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showStageChangeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _parseColor(_deal!.stage!.color),
                  foregroundColor: Colors.white,
                ),
                child: Text('Move'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final client = _deal!.client;
    final lead = _deal!.lead;
    final isClient = client != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isClient ? 'Client'.tr() : 'Lead'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF667eea),
                child: Text(
                  (isClient ? (client.name ?? 'U') : (lead?.name ?? 'U'))[0]
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClient
                          ? (client.name ?? 'Unknown'.tr())
                          : (lead?.name ?? 'Unknown'.tr()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    if (isClient
                        ? client.email != null
                        : lead?.email != null) ...[
                      Text(
                        isClient ? client.email! : lead!.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (isClient
                        ? client.companyName != null
                        : lead?.companyName != null) ...[
                      Text(
                        isClient ? client.companyName! : lead!.companyName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _deal!.team.map((member) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF667eea).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF667eea),
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTasksSection() {
    final tasks = _deal!.tasks!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks Summary'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTaskCard(
                'Total'.tr(),
                '${tasks.count}',
                Icons.assignment,
                const Color(0xFF3498db),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTaskCard(
                'Completed'.tr(),
                '${tasks.completed}',
                Icons.check_circle,
                const Color(0xFF2ecc71),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTaskCard(
                'Pending'.tr(),
                '${tasks.pending}',
                Icons.pending,
                const Color(0xFFf39c12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title.tr(),
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF2c3e50),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final location = _deal!.locationInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location.address != null) ...[
                _buildContactRow(
                    Icons.location_on, 'Address'.tr(), location.address!),
                const SizedBox(height: 8),
              ],
              if (location.city != null) ...[
                _buildContactRow(
                    Icons.location_city, 'City'.tr(), location.city!),
                const SizedBox(height: 8),
              ],
              if (location.country != null) ...[
                _buildContactRow(
                    Icons.public, 'Country'.tr(), location.country!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showStageChangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<DealsProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: Text('Move Deal to Stage'.tr()),
              content: provider.stages.isEmpty
                  ? Text('Loading stages...'.tr())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: provider.stages.map((stage) {
                        return ListTile(
                          leading: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _parseColor(stage['color'] ?? '#6c757d'),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          title: Text(stage['name'] ?? 'Unknown'.tr()),
                          onTap: () {
                            provider.moveDealToStage(
                                widget.dealId, stage['id']);
                            Navigator.pop(context);
                            _loadDeal(); // Refresh deal data
                          },
                        );
                      }).toList(),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Deal'.tr()),
          content: Text(
              'Are you sure you want to delete this deal? This action cannot be undone.'
                  .tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider =
                    Provider.of<DealsProvider>(context, listen: false);
                final success = await provider.deleteDeal(widget.dealId);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deal deleted successfully'.tr())),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'.tr()),
            ),
          ],
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
