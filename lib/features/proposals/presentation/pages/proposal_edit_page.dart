import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/proposals_provider.dart';
import '../../../../core/models/proposal.dart';
import '../widgets/proposal_item_card.dart';

class ProposalEditPage extends StatefulWidget {
  final Proposal? proposal;

  const ProposalEditPage({
    super.key,
    this.proposal,
  });

  @override
  State<ProposalEditPage> createState() => _ProposalEditPageState();
}

class _ProposalEditPageState extends State<ProposalEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _discountController;

  DateTime? _expiryDate;
  int? _selectedStatusId;
  int? _selectedClientId;
  int? _assignedToId;
  String? _modelType;
  int? _modelId;

  List<ProposalItem> _items = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.proposal != null;

    _titleController =
        TextEditingController(text: widget.proposal?.title ?? '');
    _contentController =
        TextEditingController(text: widget.proposal?.content ?? '');
    _discountController = TextEditingController(
        text: widget.proposal?.financial.discountAmount.toString() ?? '0');

    if (widget.proposal != null) {
      _expiryDate = widget.proposal!.dates.expiryDate;
      _selectedStatusId = widget.proposal!.status.id;
      _selectedClientId = widget.proposal!.client?.id;
      _assignedToId = widget.proposal!.assignedTo?.id;
      _modelType = widget.proposal!.model.type;
      _modelId = widget.proposal!.model.id;
      _items = List.from(widget.proposal!.itemsList);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProposalsProvider>(context, listen: false);
      provider.loadStatuses();
      provider.loadAvailableItems();
      provider.loadItemGroups();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _discountController.dispose();
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildBasicInfo(),
                          const SizedBox(height: 24),
                          _buildClientSelection(),
                          const SizedBox(height: 24),
                          _buildStatusSelection(),
                          const SizedBox(height: 24),
                          _buildDateSelection(),
                          const SizedBox(height: 24),
                          _buildItemsSection(),
                          const SizedBox(height: 24),
                          _buildFinancialSection(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                          const SizedBox(height: 32),
                        ],
                      ),
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
                  (_isEditMode ? 'Edit Proposal' : 'Create Proposal').tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (_isEditMode
                          ? 'Update proposal details'
                          : 'Fill in proposal information')
                      .tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
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
              const Icon(Icons.info_outline,
                  color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Basic Information'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Proposal Title *'.tr(),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter proposal title'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Description'.tr(),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelection() {
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
              const Icon(Icons.person_outline,
                  color: Color(0xFF1B4D3E), size: 20),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedClientId,
            decoration: InputDecoration(
              labelText: 'Select Client'.tr(),
              border: const OutlineInputBorder(),
            ),
            items: [
              // For demo purposes - you'd load actual clients from provider
              DropdownMenuItem(value: 1, child: Text('Client 1'.tr())),
              DropdownMenuItem(value: 2, child: Text('Client 2'.tr())),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClientId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection() {
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
              const Icon(Icons.flag_outlined,
                  color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Status & Assignment'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ProposalsProvider>(
            builder: (context, provider, child) {
              return DropdownButtonFormField<int>(
                value: _selectedStatusId,
                decoration: InputDecoration(
                  labelText: 'Status'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: provider.statuses
                    .map((status) => DropdownMenuItem(
                          value: status.id,
                          child: Text(status.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatusId = value;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
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
              const Icon(Icons.calendar_today,
                  color: Color(0xFF1B4D3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Date Information'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _expiryDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _expiryDate != null
                        ? 'Valid Until: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            .tr()
                        : 'Select Expiry Date'.tr(),
                    style: TextStyle(
                      color: _expiryDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
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
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add, size: 20),
                label: Text('Add Item'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No items added yet'.tr(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Item" to start adding items'.tr(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 200,
                  ),
                  child: ProposalItemCard(
                    item: item,
                    onEdit: () => _showEditItemDialog(index),
                    onDelete: () => _removeItem(index),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final tax = _items.fold<double>(
        0, (sum, item) => sum + (item.subtotal * item.tax / 100));
    final discount = double.tryParse(_discountController.text) ?? 0;
    final total = subtotal + tax - discount;

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
          const SizedBox(height: 16),
          TextFormField(
            controller: _discountController,
            decoration: InputDecoration(
              labelText: 'Discount Amount'.tr(),
              prefixText: '\$ ',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update totals
            },
          ),
          const SizedBox(height: 16),
          _buildFinancialRow(
              'Subtotal'.tr(), '\$${subtotal.toStringAsFixed(2)}'),
          if (tax > 0)
            _buildFinancialRow('Tax'.tr(), '\$${tax.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildFinancialRow(
                'Discount'.tr(), '-\$${discount.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _buildFinancialRow(
            'Total'.tr(),
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B4D3E)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Cancel'.tr(),
              style: const TextStyle(color: Color(0xFF1B4D3E)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProposal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text((_isEditMode ? 'Update' : 'Create').tr()),
          ),
        ),
      ],
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
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF1B4D3E) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(int index) {
    _showItemDialog(item: _items[index], index: index);
  }

  void _showItemDialog({ProposalItem? item, int? index}) {
    final nameController = TextEditingController(text: item?.itemName ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '1');
    final priceController =
        TextEditingController(text: item?.unitPrice.toString() ?? '0');
    final taxController =
        TextEditingController(text: item?.tax.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((item != null ? 'Edit Item' : 'Add Item').tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Item Name *'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'.tr()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity *'.tr()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Unit Price *'.tr()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taxController,
                decoration: InputDecoration(labelText: 'Tax Rate (%)'.tr()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;
              final tax = double.tryParse(taxController.text) ?? 0;

              if (name.isNotEmpty && quantity > 0 && price >= 0) {
                final subtotal = quantity * price;
                final newItem = ProposalItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch,
                  itemName: name,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  quantity: quantity,
                  unitPrice: price,
                  subtotal: subtotal,
                  tax: tax,
                  total: subtotal + (subtotal * tax / 100),
                );

                setState(() {
                  if (index != null) {
                    _items[index] = newItem;
                  } else {
                    _items.add(newItem);
                  }
                });

                Navigator.pop(context);
              }
            },
            child: Text((item != null ? 'Update' : 'Add').tr()),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Item'.tr()),
        content: Text('Are you sure you want to remove this item?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProposal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ProposalsProvider>(context, listen: false);

      final subtotal =
          _items.fold<double>(0, (sum, item) => sum + item.subtotal);
      final taxAmount = _items.fold<double>(
          0, (sum, item) => sum + (item.subtotal * item.tax / 100));
      final discount = double.tryParse(_discountController.text) ?? 0;
      final total = subtotal + taxAmount - discount;

      final data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'status_id': _selectedStatusId,
        'client_id': _selectedClientId,
        'assigned_to': _assignedToId,
        'expiry_date': _expiryDate?.toIso8601String().split('T')[0],
        'model_type': _modelType,
        'model_id': _modelId,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discount,
        'total': total,
        'items': _items
            .map((item) => {
                  'item_name': item.itemName,
                  'description': item.description,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                  'tax': item.tax,
                })
            .toList(),
      };

      bool success;
      if (_isEditMode) {
        success = await provider.updateProposal(widget.proposal!.id, data);
      } else {
        success = await provider.createProposal(data);
      }

      if (success && mounted) {
        Navigator.pop(context, provider.selectedProposal ?? widget.proposal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((_isEditMode
                    ? 'Proposal updated successfully'
                    : 'Proposal created successfully')
                .tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save proposal: ${e.toString()}'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
