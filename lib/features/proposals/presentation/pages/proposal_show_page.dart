import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/proposals_provider.dart';
import '../../../../core/models/proposal.dart';
import '../widgets/proposal_item_card.dart';
import 'proposal_edit_page.dart';

class ProposalShowPage extends StatefulWidget {
  final Proposal proposal;

  const ProposalShowPage({
    super.key,
    required this.proposal,
  });

  @override
  State<ProposalShowPage> createState() => _ProposalShowPageState();
}

class _ProposalShowPageState extends State<ProposalShowPage> {
  late Proposal _proposal;

  @override
  void initState() {
    super.initState();
    _proposal = widget.proposal;
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildProposalHeader(),
                        const SizedBox(height: 24),
                        _buildClientInfo(),
                        const SizedBox(height: 24),
                        _buildProposalDetails(),
                        const SizedBox(height: 24),
                        if (_proposal.itemsList.isNotEmpty) ...[
                          _buildItemsList(),
                          const SizedBox(height: 24),
                        ],
                        _buildFinancialSummary(),
                        const SizedBox(height: 24),
                        if (_proposal.conversion.isConverted) ...[
                          _buildConversionInfo(),
                          const SizedBox(height: 24),
                        ],
                        _buildActionButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
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
                  _proposal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Proposal Details'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Text('Edit'.tr()),
                  ],
                ),
              ),
              if (!_proposal.conversion.isConverted)
                PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      const Icon(Icons.transform, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Convert to Invoice'.tr()),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Delete'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProposalHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.1),
            const Color(0xFF40916C).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.1)),
      ),
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
                      _proposal.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_proposal.description.isNotEmpty)
                      Text(
                        _proposal.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_proposal.statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _proposal.statusName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _proposal.formattedTotal,
                    style: const TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Client Information'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Name'.tr(), _proposal.clientName),
          if (_proposal.clientEmail.isNotEmpty)
            _buildInfoRow('Email'.tr(), _proposal.clientEmail),
          if (_proposal.clientPhone.isNotEmpty)
            _buildInfoRow('Phone'.tr(), _proposal.clientPhone),
          if (_proposal.clientAddress.isNotEmpty)
            _buildInfoRow('Company'.tr(), _proposal.clientAddress),
        ],
      ),
    );
  }

  Widget _buildProposalDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Proposal Details'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                    'Created'.tr(), _proposal.dates.formattedCreatedAt),
              ),
              Expanded(
                child: _buildInfoRow(
                    'Valid Until'.tr(), _proposal.dates.formattedValidUntil),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                    'Items'.tr(), '${_proposal.itemsCount} items'),
              ),
              Expanded(
                child: _buildInfoRow(
                  'Status'.tr(),
                  _proposal.dates.isExpired ? 'Expired'.tr() : 'Active'.tr(),
                  textColor:
                      _proposal.dates.isExpired ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (_proposal.dates.daysUntilExpiry != null &&
              !_proposal.dates.isExpired) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Expires In'.tr(),
              '${_proposal.dates.daysUntilExpiry!.toInt()} days',
              textColor:
                  _proposal.dates.daysUntilExpiry! <= 7 ? Colors.orange : null,
            ),
          ],
          if (_proposal.assignedToName.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Assigned To'.tr(), _proposal.assignedToName),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list, color: Color(0xFF1B4D3E), size: 20),
            const SizedBox(width: 8),
            Text(
              'Items'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _proposal.itemsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _proposal.itemsList[index];
            return Container(
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 200,
              ),
              child: ProposalItemCard(
                item: item,
                isReadOnly: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.05),
            const Color(0xFF40916C).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Financial Summary'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFinancialRow('Subtotal'.tr(), _proposal.formattedSubtotal),
          if (_proposal.financial.taxAmount > 0)
            _buildFinancialRow('Tax'.tr(), _proposal.formattedTax),
          if (_proposal.financial.discountAmount > 0)
            _buildFinancialRow(
                'Discount'.tr(), '-${_proposal.formattedDiscount}'),
          const Divider(height: 16),
          _buildFinancialRow(
            'Total'.tr(),
            _proposal.formattedTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.transform, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conversion Info'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              'Converted On'.tr(), _proposal.dates.formattedConvertedAt ?? ''),
          if (_proposal.conversion.invoiceNumber != null)
            _buildInfoRow(
                'Invoice Number'.tr(), _proposal.conversion.invoiceNumber!),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_proposal.conversion.isConverted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleConvertToInvoice,
              icon: const Icon(Icons.transform),
              label: Text('Convert to Invoice'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit),
            label: Text('Edit Proposal'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: textColor ?? Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF1B4D3E) : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF1B4D3E) : Colors.grey[800],
            ),
          ),
        ],
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit();
        break;
      case 'convert':
        _handleConvertToInvoice();
        break;
      case 'delete':
        _handleDelete();
        break;
    }
  }

  void _navigateToEdit() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ProposalEditPage(proposal: _proposal),
      ),
    )
        .then((updatedProposal) {
      if (updatedProposal != null) {
        setState(() {
          _proposal = updatedProposal;
        });
      }
    });
  }

  void _handleConvertToInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Convert to Invoice'.tr()),
        content: Text(
            'Are you sure you want to convert this proposal to an invoice?'
                .tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<ProposalsProvider>(context, listen: false);

              try {
                final success = await provider.convertToInvoice(_proposal.id);

                if (success) {
                  // Refresh the proposal
                  await provider.loadProposalDetails(_proposal.id);
                  final updatedProposal = provider.selectedProposal;

                  if (updatedProposal != null) {
                    setState(() {
                      _proposal = updatedProposal;
                    });
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Proposal converted to invoice successfully'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to convert proposal: ${e.toString()}'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Convert'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Proposal'.tr()),
        content: Text(
            'Are you sure you want to delete this proposal? This action cannot be undone.'
                .tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<ProposalsProvider>(context, listen: false);

              try {
                final success = await provider.deleteProposal(_proposal.id);

                if (success && mounted) {
                  Navigator.of(context).pop(); // Go back to proposals list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Proposal deleted successfully'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to delete proposal: ${e.toString()}'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );
  }
}
