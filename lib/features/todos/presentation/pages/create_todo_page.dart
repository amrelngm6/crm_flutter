import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/todos_provider.dart';
import '../../../../core/models/todo.dart';

class CreateTodoPage extends StatefulWidget {
  final Todo? todo;

  const CreateTodoPage({super.key, this.todo});

  @override
  State<CreateTodoPage> createState() => _CreateTodoPageState();
}

class _CreateTodoPageState extends State<CreateTodoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  TodoPriority? _selectedPriority;
  DateTime? _selectedDate;
  bool _isLoading = false;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _descriptionController.text = widget.todo!.description;
      _selectedPriority = widget.todo!.priority;
      if (widget.todo!.dateInfo.date != null) {
        try {
          _selectedDate = DateTime.parse(widget.todo!.dateInfo.date!);
        } catch (e) {
          _selectedDate = null;
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodosProvider>();
      provider.loadPriorities().then((_) {
        // Set default priority if not editing and no priority is selected
        if (!isEditing &&
            _selectedPriority == null &&
            provider.priorities.isNotEmpty) {
          setState(() {
            _selectedPriority = provider.priorities.first;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
              Color(0xFF1B4D3E), // Dashboard green
              Color(0xFF2D5A47),
              Color(0xFF52D681),
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
              isEditing ? 'Edit Todo' : 'Create Todo',
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildPrioritySelector(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const Spacer(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter todo description...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF52D681)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 8),
        Consumer<TodosProvider>(
          builder: (context, provider, child) {
            if (provider.priorities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: const Text(
                  'Loading priorities...',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TodoPriority>(
                  value: _selectedPriority,
                  hint: const Text('Select priority'),
                  isExpanded: true,
                  onChanged: (TodoPriority? value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                  items: provider.priorities.map((TodoPriority priority) {
                    return DropdownMenuItem<TodoPriority>(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority.name),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(priority.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'Due Date'.tr()} (${'Optional'.tr()})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4D3E),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select due date'.tr(),
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.black
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = null;
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF52D681)),
              ),
            ),
            child: Text(
              'Cancel'.tr(),
              style: const TextStyle(
                color: Color(0xFF52D681),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTodo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52D681),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    (isEditing ? 'Update' : 'Create').tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF52D681),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<TodosProvider>();
      final description = _descriptionController.text.trim();
      final dateString = _selectedDate?.toIso8601String().split('T')[0];

      bool success;
      String? errorMessage;

      if (isEditing) {
        final updateData = <String, dynamic>{
          'description': description,
        };
        if (_selectedPriority?.id != null) {
          updateData['priority_id'] = _selectedPriority!.id;
        }
        if (dateString != null) {
          updateData['date'] = dateString;
        }

        final result =
            await provider.updateTodoWithError(widget.todo!.id, updateData);
        success = result['success'] ?? false;
        errorMessage = result['error'];
      } else {
        final createData = <String, dynamic>{
          'description': description,
        };

        // Always send priority_id - use selected priority or first available priority
        if (_selectedPriority?.id != null) {
          createData['priority_id'] = _selectedPriority!.id;
        } else {
          // Use the first available priority as default if none selected
          final priorities = provider.priorities;
          if (priorities.isNotEmpty) {
            createData['priority_id'] = priorities.first.id;
          }
        }

        if (dateString != null) {
          createData['date'] = dateString;
        }

        final result = await provider.createTodo(createData);

        if (!result && provider.error != null) {
          _showError(provider.error ?? 'An unknown error occurred');
        }
      }

      if (mounted && provider.error == null) {
        Navigator.pop(context);
        _showSuccess(
          isEditing ? 'Todo updated successfully' : 'Todo created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF52D681),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
