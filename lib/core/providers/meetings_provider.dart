import 'package:flutter/foundation.dart';
import '../models/meeting.dart';
import '../services/api_service.dart';

class MeetingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Meeting> _meetings = [];
  List<Meeting> _filteredMeetings = [];
  List<MeetingStatus> _statuses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String? _selectedStatus;
  bool _myMeetingsOnly = true;
  bool _todayOnly = false;
  bool _upcomingOnly = false;
  Map<String, dynamic>? _statistics;

  // Getters
  List<Meeting> get meetings => _filteredMeetings;
  List<MeetingStatus> get statuses => _statuses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  bool get myMeetingsOnly => _myMeetingsOnly;
  bool get todayOnly => _todayOnly;
  bool get upcomingOnly => _upcomingOnly;
  Map<String, dynamic>? get statistics => _statistics;

  // Statistics getters
  int get totalMeetings => _statistics?['overview']?['total_meetings'] ?? 0;
  int get todayMeetings => _statistics?['overview']?['today_meetings'] ?? 0;
  int get upcomingMeetings =>
      _statistics?['overview']?['upcoming_meetings'] ?? 0;
  int get completedMeetings =>
      _statistics?['overview']?['completed_meetings'] ?? 0;

  // Status counts
  int get scheduledCount =>
      meetings.where((m) => m.status.id == 'scheduled').length;
  int get inProgressCount =>
      meetings.where((m) => m.status.id == 'in_progress').length;
  int get completedCount =>
      meetings.where((m) => m.status.id == 'completed').length;
  int get cancelledCount =>
      meetings.where((m) => m.status.id == 'cancelled').length;

  // Filter counts
  int get pastCount => meetings.where((m) => m.isPast).length;
  int get todayCount => meetings.where((m) => m.isToday).length;
  int get upcomingCount => meetings.where((m) => m.isUpcoming).length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadMeetings({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _meetings.clear();
      _filteredMeetings.clear();
    }

    if (_isLoading || !_hasMoreData) return;

    _setLoading(true);
    _setError(null);

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'per_page': 20,
        'my_meetings_only': _myMeetingsOnly,
        'today_only': _todayOnly,
        'upcoming_only': _upcomingOnly,
      };

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      if (_selectedStatus != null) {
        params['status'] = _selectedStatus;
      }

      final response = await _apiService.getMeetings(params);

      if (response['success'] == true) {
        final meetingsData = response['data']['meetings'] as List;
        final newMeetings =
            meetingsData.map((json) => Meeting.fromJson(json)).toList();

        if (refresh) {
          _meetings = newMeetings;
        } else {
          _meetings.addAll(newMeetings);
        }

        _filteredMeetings = List.from(_meetings);

        final pagination = response['data']['pagination'];
        _hasMoreData = pagination['current_page'] < pagination['last_page'];
        _currentPage++;
      } else {
        _setError(response['message'] ?? 'Failed to load meetings');
      }
    } catch (e) {
      print('Error loading meetings: $e');
      _setError('Error loading meetings: ${e.toString()}');

      // Fallback to mock data for development
      if (_meetings.isEmpty) {
        _loadMockMeetings();
      }
    }

    _setLoading(false);
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getMeetingsStatistics();
      _statistics = response['data'] ?? {};
      notifyListeners();
    } catch (e) {
      print('Error loading statistics: $e');
      _loadMockStatistics();
    }
  }

  Future<Meeting?> getMeeting(int id) async {
    try {
      final response = await _apiService.getMeeting(id);
      if (response['success'] == true) {
        return Meeting.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting meeting: $e');
      return null;
    }
  }

  Future<bool> createMeeting(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createMeeting(data);
      if (response['success'] == true) {
        await loadMeetings(refresh: true);
        await loadStatistics();
        return true;
      }
      _setError(response['message'] ?? 'Failed to create meeting');
      return false;
    } catch (e) {
      print('Error creating meeting: $e');
      _setError('Error creating meeting: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateMeeting(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateMeeting(id, data);
      if (response['success'] == true) {
        await loadMeetings(refresh: true);
        await loadStatistics();
        return true;
      }
      _setError(response['message'] ?? 'Failed to update meeting');
      return false;
    } catch (e) {
      print('Error updating meeting: $e');
      _setError('Error updating meeting: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMeeting(int id) async {
    try {
      final response = await _apiService.deleteMeeting(id);
      if (response['success'] == true) {
        await loadMeetings(refresh: true);
        await loadStatistics();
        return true;
      }
      _setError(response['message'] ?? 'Failed to delete meeting');
      return false;
    } catch (e) {
      print('Error deleting meeting: $e');
      _setError('Error deleting meeting: ${e.toString()}');
      return false;
    }
  }

  Future<CalendarEvent?> getCalendarEvents(DateTime date) async {
    try {
      final response = await _apiService.getCalendarEvents(date.toString());
      if (response['success'] == true) {
        return CalendarEvent.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting calendar events: $e');
      return null;
    }
  }

  // Filtering and searching
  void searchMeetings(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  void filterByStatus(String? status) {
    _selectedStatus = status;
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  void toggleMyMeetingsOnly() {
    _myMeetingsOnly = !_myMeetingsOnly;
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  void toggleTodayOnly() {
    _todayOnly = !_todayOnly;
    _upcomingOnly = false; // Can't have both
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  void toggleUpcomingOnly() {
    _upcomingOnly = !_upcomingOnly;
    _todayOnly = false; // Can't have both
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _myMeetingsOnly = true;
    _todayOnly = false;
    _upcomingOnly = false;
    _currentPage = 1;
    _hasMoreData = true;
    loadMeetings(refresh: true);
  }

  // Mock data methods for development
  void _loadMockMeetings() {
    _meetings = [
      Meeting(
        id: 1,
        title: 'Project Kickoff Meeting',
        description: 'Initial project discussion and planning',
        startDate: DateTime.now().add(const Duration(hours: 2)),
        endDate: DateTime.now().add(const Duration(hours: 3)),
        durationMinutes: 60,
        location: 'Conference Room A',
        meetingUrl: 'https://zoom.us/j/123456789',
        reminderMinutes: 15,
        isRecurring: false,
        status: MeetingStatus(
          id: 'scheduled',
          name: 'Scheduled',
          color: '#007bff',
        ),
        client: MeetingClient(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          company: 'ABC Corp',
        ),
        attendees: [
          MeetingAttendee(
            id: 1,
            name: 'Sarah Wilson',
            email: 'sarah@company.com',
          ),
          MeetingAttendee(
            id: 2,
            name: 'Mike Johnson',
            email: 'mike@company.com',
          ),
        ],
        isPast: false,
        isToday: true,
        isUpcoming: true,
        timeUntilMeeting: 'in 2 hours',
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      Meeting(
        id: 2,
        title: 'Weekly Team Standup',
        description: 'Weekly progress review and planning',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1, minutes: 30)),
        durationMinutes: 30,
        location: null,
        meetingUrl: 'https://meet.google.com/abc-defg-hij',
        reminderMinutes: 10,
        isRecurring: true,
        recurringType: 'weekly',
        status: MeetingStatus(
          id: 'scheduled',
          name: 'Scheduled',
          color: '#007bff',
        ),
        client: null,
        attendees: [
          MeetingAttendee(
            id: 1,
            name: 'Sarah Wilson',
            email: 'sarah@company.com',
          ),
          MeetingAttendee(
            id: 3,
            name: 'David Brown',
            email: 'david@company.com',
          ),
          MeetingAttendee(
            id: 4,
            name: 'Emily Davis',
            email: 'emily@company.com',
          ),
        ],
        isPast: false,
        isToday: false,
        isUpcoming: true,
        timeUntilMeeting: 'tomorrow',
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),
      Meeting(
        id: 3,
        title: 'Client Presentation',
        description: 'Present quarterly results and future roadmap',
        startDate: DateTime.now().subtract(const Duration(hours: 2)),
        endDate: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        location: 'Client Office',
        meetingUrl: null,
        reminderMinutes: 30,
        isRecurring: false,
        status: MeetingStatus(
          id: 'completed',
          name: 'Completed',
          color: '#28a745',
        ),
        client: MeetingClient(
          id: 2,
          name: 'Jane Smith',
          email: 'jane@client.com',
          company: 'XYZ Ltd',
        ),
        attendees: [
          MeetingAttendee(
            id: 1,
            name: 'Sarah Wilson',
            email: 'sarah@company.com',
          ),
          MeetingAttendee(
            id: 2,
            name: 'Mike Johnson',
            email: 'mike@company.com',
          ),
        ],
        isPast: true,
        isToday: true,
        isUpcoming: false,
        timeUntilMeeting: null,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
    ];
    _filteredMeetings = List.from(_meetings);
    notifyListeners();
  }

  void _loadMockStatistics() {
    _statistics = {
      'overview': {
        'total_meetings': 15,
        'today_meetings': 3,
        'upcoming_meetings': 8,
        'completed_meetings': 12,
      },
      'status_breakdown': {
        'scheduled': 8,
        'in_progress': 1,
        'completed': 5,
        'cancelled': 1,
      }
    };
    notifyListeners();
  }
}
