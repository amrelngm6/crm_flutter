import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/tickets_provider.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  int? _selectedPriorityId;
  int? _selectedCategoryId;
  int? _selectedClientId;
  DateTime? _selectedDueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TicketsProvider>();
      if (provider.categories.isEmpty) {
        provider.getTicketFormData();
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final data = {
      'subject': _subjectController.text.trim(),
      'message': _messageController.text.trim(),
      if (_selectedPriorityId != null) 'priority_id': _selectedPriorityId,
      if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
      if (_selectedClientId != null) 'client_id': _selectedClientId,
      if (_selectedDueDate != null)
        'due_date': _selectedDueDate!.toIso8601String().split('T')[0],
    };

    final success = await context.read<TicketsProvider>().createTicket(data);

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket created successfully'.tr()),
          backgroundColor: Color(0xFF52658F),
        ),
      );
    } else if (mounted) {
      final provider = context.read<TicketsProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Failed to create ticket'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              Color(0xFF2E4057),
              Color(0xFF3F5373),
              Color(0xFF52658F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
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
                  child: _buildForm(),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Create Support Ticket'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSubjectField(),
            const SizedBox(height: 20),
            _buildMessageField(),
            const SizedBox(height: 20),
            _buildPriorityField(),
            const SizedBox(height: 20),
            _buildCategoryField(),
            const SizedBox(height: 20),
            _buildClientField(),
            const SizedBox(height: 20),
            _buildDueDateField(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'Subject'.tr()} *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E4057),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: 'Enter ticket subject'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF52658F)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Subject is required'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'Message'.tr()} *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E4057),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Describe your issue or request...'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF52658F)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Message is required'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriorityField() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedPriorityId,
                  hint: Text('Select priority'.tr()),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No priority'.tr()),
                    ),
                    ...provider.priorities.map((priority) {
                      return DropdownMenuItem<int?>(
                        value: priority.id,
                        child: Row(
                          children: [
                            Icon(
                              _getPriorityIcon(priority.level),
                              size: 16,
                              color: _getPriorityColor(priority.color),
                            ),
                            const SizedBox(width: 8),
                            Text(priority.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriorityId = value;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryField() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedCategoryId,
                  hint: Text('Select category'.tr()),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No category'.tr()),
                    ),
                    ...provider.categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name ?? 'Unknown'.tr()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientField() {
    return Consumer<TicketsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E4057),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedClientId,
                  hint: Text('Select client'.tr()),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No client'.tr()),
                    ),
                    ...provider.clients.map((client) {
                      return DropdownMenuItem<int?>(
                        value: client.id,
                        child: Text(client.name ?? 'Unknown'.tr()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDueDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E4057),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDueDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                      : 'Select due date (optional)'.tr(),
                  style: TextStyle(
                    color: _selectedDueDate != null
                        ? const Color(0xFF2E4057)
                        : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_selectedDueDate != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                    child: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF52658F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Ticket'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  Color _getPriorityColor(String? colorCode) {
    if (colorCode == null) return Colors.orange;

    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.orange;
    }
  }

  IconData _getPriorityIcon(int level) {
    switch (level) {
      case 1: // Low
        return Icons.arrow_downward;
      case 2: // Medium
        return Icons.remove;
      case 3: // High
        return Icons.arrow_upward;
      case 4: // Critical
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }
}
