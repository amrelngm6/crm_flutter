import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/meetings_provider.dart';
import '../../../../core/models/meeting.dart';

class MeetingEditPage extends StatefulWidget {
  final Meeting? meeting;

  const MeetingEditPage({
    super.key,
    this.meeting,
  });

  @override
  State<MeetingEditPage> createState() => _MeetingEditPageState();
}

class _MeetingEditPageState extends State<MeetingEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingUrlController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  int? _reminderMinutes;
  bool _isRecurring = false;
  String? _recurringType;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.meeting != null) {
      final meeting = widget.meeting!;
      _titleController.text = meeting.title;
      _descriptionController.text = meeting.description ?? '';
      _locationController.text = meeting.location ?? '';
      _meetingUrlController.text = meeting.meetingUrl ?? '';
      _startDate = meeting.startDate;
      _startTime = TimeOfDay(
          hour: meeting.startDate.hour, minute: meeting.startDate.minute);
      if (meeting.endDate != null) {
        _endDate = meeting.endDate;
        _endTime = TimeOfDay(
            hour: meeting.endDate!.hour, minute: meeting.endDate!.minute);
      }
      _reminderMinutes = meeting.reminderMinutes;
      _isRecurring = meeting.isRecurring;
      _recurringType = meeting.recurringType;
    } else {
      // Default values for new meeting
      _startDate = DateTime.now().add(const Duration(hours: 1));
      _startTime = TimeOfDay(
        hour: _startDate!.hour,
        minute: 0,
      );
      _endDate = _startDate!.add(const Duration(hours: 1));
      _endTime = TimeOfDay(
        hour: _endDate!.hour,
        minute: 0,
      );
      _reminderMinutes = 15;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingUrlController.dispose();
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
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF4CAF50),
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
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
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
                  widget.meeting != null ? 'Edit Meeting' : 'Create Meeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.meeting != null
                      ? 'Update meeting details'
                      : 'Schedule a new meeting',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildDateTime(),
            const SizedBox(height: 24),
            _buildLocation(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            // _buildOptions(),
            // const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            decoration: const InputDecoration(
              labelText: 'Meeting Title *',
              hintText: 'Enter meeting title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a meeting title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter meeting description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTime() {
    return _buildSection(
      title: 'Date & Time',
      icon: Icons.access_time,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectStartTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startTime != null
                          ? _startTime!.format(context)
                          : 'Select time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectEndTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endTime != null
                          ? _endTime!.format(context)
                          : 'Select time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return _buildSection(
      title: 'Location',
      icon: Icons.location_on,
      child: Column(
        children: [
          TextFormField(
            controller: _locationController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            decoration: const InputDecoration(
              labelText: 'Physical Location',
              hintText: 'Enter meeting location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _meetingUrlController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            decoration: const InputDecoration(
              labelText: 'Meeting URL',
              hintText: 'Enter video meeting URL',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

/*
  Widget _buildOptions() {
    return _buildSection(
      title: 'Options',
      icon: Icons.settings,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _reminderMinutes,
            decoration: const InputDecoration(
              labelText: 'Reminder',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('No reminder')),
              DropdownMenuItem(value: 5, child: Text('5 minutes before')),
              DropdownMenuItem(value: 10, child: Text('10 minutes before')),
              DropdownMenuItem(value: 15, child: Text('15 minutes before')),
              DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              DropdownMenuItem(value: 60, child: Text('1 hour before')),
            ],
            onChanged: (value) {
              setState(() {
                _reminderMinutes = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Recurring Meeting'),
            subtitle: const Text('Repeat this meeting'),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
                if (!value) {
                  _recurringType = null;
                }
              });
            },
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recurringType,
              decoration: const InputDecoration(
                labelText: 'Repeat Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                setState(() {
                  _recurringType = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
*/
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMeeting,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.meeting != null ? 'Update Meeting' : 'Create Meeting',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // If end date is before start date, update it
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _saveMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select start date and time'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_date': startDateTime.toIso8601String(),
        'end_date': endDateTime?.toIso8601String(),
        'location': _locationController.text.trim(),
        'meeting_url': _meetingUrlController.text.trim(),
        'reminder_minutes': _reminderMinutes,
        'is_recurring': _isRecurring,
        'recurring_type': _recurringType,
      };

      final meetingsProvider =
          Provider.of<MeetingsProvider>(context, listen: false);
      bool success;

      success = false;
      try {
        if (widget.meeting != null) {
          success =
              await meetingsProvider.updateMeeting(widget.meeting!.id, data);
        } else {
          success = await meetingsProvider.createMeeting(data);
        }
      } catch (e) {
        print('Error saving meeting: ${e.toString()}');
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.meeting != null
                  ? 'Meeting updated successfully'.tr()
                  : 'Meeting created successfully'.tr(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.meeting != null
                  ? 'Failed to update meeting'.tr()
                  : 'Failed to create meeting'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
