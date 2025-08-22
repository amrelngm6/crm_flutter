// ...existing code...
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/estimates_provider.dart';
import '../../../../core/models/estimate.dart';
import '../widgets/estimate_item_card.dart';
import 'estimate_edit_page.dart';

class EstimateShowPage extends StatefulWidget {
  final Estimate estimate;

  const EstimateShowPage({
    super.key,
    required this.estimate,
  });

  @override
  State<EstimateShowPage> createState() => _EstimateShowPageState();
}

class _EstimateShowPageState extends State<EstimateShowPage> {
  late Estimate _estimate;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate;
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
                        _buildEstimateHeader(),
                        const SizedBox(height: 24),
                        _buildClientInfo(),
                        const SizedBox(height: 24),
                        _buildEstimateDetails(),
                        const SizedBox(height: 24),
                        _buildItemsList(),
                        const SizedBox(height: 24),
                        _buildFinancialSummary(),
                        const SizedBox(height: 24),
                        _buildApprovalSection(),
                        if (_estimate.conversion.isConverted) ...[
                          const SizedBox(height: 24),
                          _buildConversionInfo(),
                        ],
                        const SizedBox(height: 32),
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
                  _estimate.estimateNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'estimate_details'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
                    Text('edit'.tr()),
                  ],
                ),
              ),
              if (!_estimate.approval.isApproved &&
                  !_estimate.approval.isRejected) ...[
                PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('approve'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('reject'.tr()),
                    ],
                  ),
                ),
              ],
              if (_estimate.approval.isApproved &&
                  !_estimate.conversion.isConverted)
                PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      const Icon(Icons.transform, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('convert_to_invoice'.tr()),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('delete'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withValues(alpha: 0.1),
            const Color(0xFF40916C).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF1B4D3E).withValues(alpha: 0.1)),
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
                      _estimate.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_estimate.description.isNotEmpty)
                      Text(
                        _estimate.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
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
                      color: _getStatusColor(_estimate.status.color)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _estimate.status.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(_estimate.status.color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _estimate.formattedTotal,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
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
          _buildInfoRow('Name'.tr(), _estimate.clientName),
          if (_estimate.clientEmail.isNotEmpty)
            _buildInfoRow('Email'.tr(), _estimate.clientEmail),
          if (_estimate.clientPhone.isNotEmpty)
            _buildInfoRow('Phone'.tr(), _estimate.clientPhone),
          if (_estimate.clientAddress.isNotEmpty)
            _buildInfoRow('Address'.tr(), _estimate.clientAddress),
        ],
      ),
    );
  }

  Widget _buildEstimateDetails() {
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
                'Estimate Details'.tr(),
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
                    'Created'.tr(), _estimate.dates.formattedCreatedAt),
              ),
              Expanded(
                child: _buildInfoRow(
                    'Valid Until'.tr(), _estimate.dates.formattedValidUntil),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                    'Items'.tr(), '${_estimate.itemsCount} ${'items'.tr()}'),
              ),
              Expanded(
                child: _buildInfoRow(
                  'Status'.tr(),
                  _estimate.dates.isExpired ? 'Expired'.tr() : 'Active'.tr(),
                  textColor:
                      _estimate.dates.isExpired ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (_estimate.dates.daysUntilExpiry != null &&
              !_estimate.dates.isExpired) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Expires In'.tr(),
              '${_estimate.dates.daysUntilExpiry!.toInt()} ${'days'.tr()}',
              textColor:
                  _estimate.dates.daysUntilExpiry! <= 7 ? Colors.orange : null,
            ),
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
          itemCount: _estimate.itemsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _estimate.itemsList[index];
            return EstimateItemCard(item: item);
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
            const Color(0xFF1B4D3E).withValues(alpha: 0.05),
            const Color(0xFF40916C).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1B4D3E).withValues(alpha: 0.1)),
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
          _buildFinancialRow('Subtotal'.tr(), _estimate.formattedSubtotal),
          if (_estimate.financial.taxAmount > 0)
            _buildFinancialRow('Tax'.tr(), _estimate.formattedTax),
          if (_estimate.financial.discountAmount > 0)
            _buildFinancialRow(
                'Discount'.tr(), '-${_estimate.formattedDiscount}'),
          const Divider(height: 16),
          _buildFinancialRow(
            'Total'.tr(),
            _estimate.formattedTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getApprovalColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getApprovalColor().withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getApprovalIcon(), color: _getApprovalColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Approval Status'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getApprovalColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getApprovalColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _estimate.approval.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (_estimate.approval.approvedAt != null ||
                  _estimate.approval.rejectedAt != null)
                Text(
                  _estimate.approval.approvedAt != null
                      ? '${'Approved on'.tr()} ${_estimate.approval.formattedApprovedAt}'
                      : '${'Rejected on'.tr()} ${_estimate.approval.formattedRejectedAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (_estimate.approval.approvedBy != null ||
              _estimate.approval.rejectedBy != null) ...[
            const SizedBox(height: 8),
            Text(
              '${'By'.tr()}: ${_estimate.approval.approvedBy ?? _estimate.approval.rejectedBy}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (_estimate.approval.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              '${'Reason'.tr()}: ${_estimate.approval.rejectionReason}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
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
          _buildInfoRow('Converted On'.tr(),
              _estimate.conversion.formattedConvertedAt ?? ''),
          if (_estimate.conversion.invoiceNumber != null)
            _buildInfoRow(
                'Invoice Number'.tr(), _estimate.conversion.invoiceNumber!),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_estimate.approval.isApproved &&
            !_estimate.approval.isRejected) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApproval(true),
                  icon: const Icon(Icons.check_circle),
                  label: Text('Approve'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApproval(false),
                  icon: const Icon(Icons.cancel),
                  label: Text('Reject'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_estimate.approval.isApproved &&
            !_estimate.conversion.isConverted) ...[
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
            label: Text('Edit Estimate'.tr()),
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

  Color _getApprovalColor() {
    if (_estimate.approval.isApproved) return Colors.green;
    if (_estimate.approval.isRejected) return Colors.red;
    return Colors.orange;
  }

  IconData _getApprovalIcon() {
    if (_estimate.approval.isApproved) return Icons.check_circle;
    if (_estimate.approval.isRejected) return Icons.cancel;
    return Icons.pending;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit();
        break;
      case 'approve':
        _handleApproval(true);
        break;
      case 'reject':
        _handleApproval(false);
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
        builder: (context) => EstimateEditPage(estimate: _estimate),
      ),
    )
        .then((updatedEstimate) {
      if (updatedEstimate != null) {
        setState(() {
          _estimate = updatedEstimate;
        });
      }
    });
  }

  void _handleApproval(bool approve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Estimate'.tr() : 'Reject Estimate'.tr()),
        content: approve
            ? Text('Are you sure you want to approve this estimate?'.tr())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Please provide a reason for rejection:'.tr()),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Rejection reason...'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Store reason
                    },
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<EstimatesProvider>(context, listen: false);

              try {
                if (approve) {
                  await provider.approveEstimate(_estimate.id);
                } else {
                  await provider.rejectEstimate(_estimate.id);
                }

                // Refresh the estimate
                final updatedEstimate = provider.estimates.firstWhere(
                  (e) => e.id == _estimate.id,
                  orElse: () => _estimate,
                );

                setState(() {
                  _estimate = updatedEstimate;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(approve
                          ? 'Estimate approved'.tr()
                          : 'Estimate rejected'.tr()),
                      backgroundColor: approve ? Colors.green : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(approve
                          ? 'Failed to approve estimate'.tr()
                          : 'Failed to reject estimate'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve'.tr() : 'Reject'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleConvertToInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Convert to Invoice'.tr()),
        content: Text(
            'Are you sure you want to convert this estimate to an invoice?'
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
                  Provider.of<EstimatesProvider>(context, listen: false);

              try {
                await provider.convertToInvoice(_estimate.id);

                // Refresh the estimate
                final updatedEstimate = provider.estimates.firstWhere(
                  (e) => e.id == _estimate.id,
                  orElse: () => _estimate,
                );

                setState(() {
                  _estimate = updatedEstimate;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estimate converted to invoice'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to convert estimate'.tr()),
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
        title: Text('Delete Estimate'.tr()),
        content: Text(
            'Are you sure you want to delete this estimate? This action cannot be undone.'
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
                  Provider.of<EstimatesProvider>(context, listen: false);

              try {
                await provider.deleteEstimate(_estimate.id);

                if (mounted) {
                  Navigator.of(context).pop(); // Go back to estimates list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estimate deleted'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete estimate'.tr()),
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
