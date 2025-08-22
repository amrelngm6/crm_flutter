import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class TicketsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Ticket> _tickets = [];
  List<TicketStatus> _statuses = [];
  List<TicketPriority> _priorities = [];
  List<TicketCategory> _categories = [];
  List<TicketClient> _clients = [];
  List<TicketStaff> _staffMembers = [];
  Ticket? _selectedTicket;
  Map<String, dynamic> _statistics = {};

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalTickets = 0;
  bool _hasMoreData = true;

  // Search and filter state
  String _searchQuery = '';
  int? _selectedStatusId;
  int? _selectedPriorityId;
  int? _selectedCategoryId;
  int? _selectedClientId;
  String? _modelType;
  int? _modelId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _createdStartDate;
  DateTime? _createdEndDate;
  bool? _overdue;
  bool? _dueSoon;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  bool _myTicketsOnly = false;

  // Getters
  List<Ticket> get tickets => _tickets;
  List<TicketStatus> get statuses => _statuses;
  List<TicketPriority> get priorities => _priorities;
  List<TicketCategory> get categories => _categories;
  List<TicketClient> get clients => _clients;
  List<TicketStaff> get staffMembers => _staffMembers;
  Ticket? get selectedTicket => _selectedTicket;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalTickets => _totalTickets;
  bool get hasMoreData => _hasMoreData;

  // Filter getters
  String get searchQuery => _searchQuery;
  int? get selectedStatusId => _selectedStatusId;
  int? get selectedPriorityId => _selectedPriorityId;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedClientId => _selectedClientId;
  String? get modelType => _modelType;
  int? get modelId => _modelId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  DateTime? get createdStartDate => _createdStartDate;
  DateTime? get createdEndDate => _createdEndDate;
  bool? get overdue => _overdue;
  bool? get dueSoon => _dueSoon;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get myTicketsOnly => _myTicketsOnly;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize data
  Future<void> initialize() async {
    await Future.wait([loadTickets(refresh: true)]);

    await Future.wait([
      getTicketFormData(),
      loadStatistics(),
    ]);
  }

  // Load tickets with pagination and filters
  Future<void> loadTickets({
    bool refresh = false,
    int? page,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _tickets.clear();
    }

    if (!_hasMoreData && !refresh) return;

    final targetPage = page ?? _currentPage;

    if (targetPage == 1 || refresh) {
      _isLoading = true;
    }

    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTickets(
        page: targetPage,
        perPage: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        statusId: _selectedStatusId,
        priorityId: _selectedPriorityId,
        categoryId: _selectedCategoryId,
        clientId: _selectedClientId,
        modelType: _modelType,
        modelId: _modelId,
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        createdStartDate: _createdStartDate?.toIso8601String().split('T')[0],
        createdEndDate: _createdEndDate?.toIso8601String().split('T')[0],
        overdue: _overdue,
        dueSoon: _dueSoon,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        myTicketsOnly: _myTicketsOnly,
      );

      final ticketsData = response['data']['tickets'] as List;
      final newTickets =
          ticketsData.map((json) => Ticket.fromJson(json)).toList();

      if (refresh || targetPage == 1) {
        _tickets = newTickets;
      } else {
        _tickets.addAll(newTickets);
      }

      final pagination = response['data']['pagination'] ?? {};
      _currentPage = pagination['current_page'] ?? 1;
      _lastPage = pagination['last_page'] ?? 1;
      _totalTickets = pagination['total'] ?? 0;
      _hasMoreData = _currentPage < _lastPage;

      if (_hasMoreData) {
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to load tickets: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading tickets: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (!_hasMoreData || _isLoading) return;
    await loadTickets();
  }

  // Search tickets
  Future<void> searchTickets(String query) async {
    _searchQuery = query;
    await loadTickets(refresh: true);
  }

  // Filter methods
  Future<void> filterByStatus(int? statusId) async {
    _selectedStatusId = statusId;
    await loadTickets(refresh: true);
  }

  Future<void> filterByPriority(int? priorityId) async {
    _selectedPriorityId = priorityId;
    await loadTickets(refresh: true);
  }

  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await loadTickets(refresh: true);
  }

  Future<void> filterByClient(int? clientId) async {
    _selectedClientId = clientId;
    await loadTickets(refresh: true);
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    await loadTickets(refresh: true);
  }

  Future<void> filterByCreatedDateRange(DateTime? start, DateTime? end) async {
    _createdStartDate = start;
    _createdEndDate = end;
    await loadTickets(refresh: true);
  }

  Future<void> resetOverdueFilter() async {
    _overdue = null;
    _dueSoon = null;
  }

  Future<void> toggleOverdueFilter() async {
    _overdue = true;
    await loadTickets(refresh: true);
  }

  Future<void> toggleDueSoonFilter() async {
    _dueSoon = true;
    await loadTickets(refresh: true);
  }

  Future<void> toggleMyTicketsOnly() async {
    _myTicketsOnly = !_myTicketsOnly;
    await loadTickets(refresh: true);
  }

  Future<void> setSorting(String sortBy, String sortOrder) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    await loadTickets(refresh: true);
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedStatusId = null;
    _selectedPriorityId = null;
    _selectedCategoryId = null;
    _selectedClientId = null;
    _modelType = null;
    _modelId = null;
    _startDate = null;
    _endDate = null;
    _createdStartDate = null;
    _createdEndDate = null;
    _overdue = null;
    _dueSoon = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    _myTicketsOnly = false;
    await loadTickets(refresh: true);
  }

  // Load ticket details
  Future<void> loadTicketDetails(int id) async {
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTicket(id);
      _selectedTicket = Ticket.fromJson(response['data']);
    } catch (e) {
      _error = 'Failed to load ticket details: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading ticket details: $e');
      }
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Create ticket
  Future<bool> createTicket(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createTicket(data);
      final newTicket = Ticket.fromJson(response['data']);

      _tickets.insert(0, newTicket);
      _totalTickets++;

      return true;
    } catch (e) {
      _error = 'Failed to create ticketsss: ${_apiService.error}';
      if (kDebugMode) {
        print('Error creating ticket: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update ticket
  Future<bool> updateTicket(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateTicket(id, data);
      final updatedTicket = Ticket.fromJson(response['data']);

      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      if (_selectedTicket?.id == id) {
        _selectedTicket = updatedTicket;
      }

      return true;
    } catch (e) {
      _error = 'Failed to update ticket: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating ticket: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete ticket
  Future<bool> deleteTicket(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteTicket(id);

      _tickets.removeWhere((t) => t.id == id);
      _totalTickets--;

      if (_selectedTicket?.id == id) {
        _selectedTicket = null;
      }

      return true;
    } catch (e) {
      _error = 'Failed to delete ticket: ${e.toString()}';
      if (kDebugMode) {
        print('Error deleting ticket: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reply to ticket
  Future<bool> replyToTicket(int id, String content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.replyToTicket(id, content);

      // Reload ticket details to get updated comments
      await loadTicketDetails(id);

      return true;
    } catch (e) {
      _error = 'Failed to reply to ticket: ${e.toString()}';
      if (kDebugMode) {
        print('Error replying to ticket: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change ticket status
  Future<bool> changeTicketStatus(int id, int statusId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.changeTicketStatus(id, statusId);

      // Update the ticket in the list
      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) {
        final status = _statuses.firstWhere((s) => s.id == statusId);
        _tickets[index] = _tickets[index].copyWith(
          status: status,
        );
      }

      // Update selected ticket if it's the same
      if (_selectedTicket?.id == id) {
        await loadTicketDetails(id);
      }

      return true;
    } catch (e) {
      _error = 'Failed to change ticket status: ${e.toString()}';
      if (kDebugMode) {
        print('Error changing ticket status: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign staff to ticket
  Future<bool> assignStaff(int id, List<int> staffIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.assignTicketStaff(id, staffIds);

      // Reload ticket details to get updated staff assignments
      await loadTicketDetails(id);

      return true;
    } catch (e) {
      _error = 'Failed to assign staff: ${e.toString()}';
      if (kDebugMode) {
        print('Error assigning staff: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove staff from ticket
  Future<bool> removeStaff(int id, List<int> staffIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.removeTicketStaff(id, staffIds);

      // Reload ticket details to get updated staff assignments
      await loadTicketDetails(id);

      return true;
    } catch (e) {
      _error = 'Failed to remove staff: ${e.toString()}';
      if (kDebugMode) {
        print('Error removing staff: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTicketFormData() async {
    try {
      final response = await _apiService.getTicketFormData();
      final categoriesData = response['categories'] as List;
      _categories =
          categoriesData.map((json) => TicketCategory.fromJson(json)).toList();

      final prioritiesData = response['priorities'] as List;
      _priorities =
          prioritiesData.map((json) => TicketPriority.fromJson(json)).toList();

      final statusesData = response['statuses'] as List;
      _statuses =
          statusesData.map((json) => TicketStatus.fromJson(json)).toList();

      final clientsData = response['clients'] as List;
      _clients =
          clientsData.map((json) => TicketClient.fromJson(json)).toList();

      final staffData = response['staff'] as List;
      _staffMembers =
          staffData.map((json) => TicketStaff.fromJson(json)).toList();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ticket categories: $e');
      }
    }
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getTicketStatistics();
      _statistics = response['data'] ?? {};
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ticket statistics: $e');
      }
    }
  }

  // Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    notifyListeners();
  }

  // Helper methods
  Ticket? getTicketById(int id) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      return null;
    }
  }

  TicketStatus? getStatusById(int id) {
    try {
      return _statuses.firstWhere((status) => status.id == id);
    } catch (e) {
      return null;
    }
  }

  TicketPriority? getPriorityById(int id) {
    try {
      return _priorities.firstWhere((priority) => priority.id == id);
    } catch (e) {
      return null;
    }
  }

  TicketCategory? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  TicketClient? getClientById(int id) {
    try {
      return _clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  TicketStaff? getStaffById(int id) {
    try {
      return _staffMembers.firstWhere((staff) => staff.id == id);
    } catch (e) {
      return null;
    }
  }
}
