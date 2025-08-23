import 'package:flutter/foundation.dart';
import '../models/estimate_request.dart';
import '../services/api_service.dart';

class EstimateRequestsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estimate Requests
  List<EstimateRequest> _estimateRequests = [];
  EstimateRequest? _selectedEstimateRequest;
  Map<String, dynamic> _statistics = {};

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRequests = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Search and filter state
  String _searchQuery = '';
  int? _statusFilter;
  int? _assignedToFilter;
  String? _userTypeFilter;
  int? _userIdFilter;
  String? _startDate;
  String? _endDate;
  bool? _unassignedFilter;
  bool? _hasEstimateFilter;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  // Form data
  List<EstimateRequestStatus> _statusOptions = [];
  List<Map<String, dynamic>> _staffMembers = [];
  Map<String, dynamic> _requestSettings = {};

  // Getters
  List<EstimateRequest> get estimateRequests => _estimateRequests;
  EstimateRequest? get selectedEstimateRequest => _selectedEstimateRequest;
  Map<String, dynamic> get statistics => _statistics;

  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRequests => _totalRequests;
  bool get hasMoreData => _hasMoreData;

  String get searchQuery => _searchQuery;
  int? get statusFilter => _statusFilter;
  int? get assignedToFilter => _assignedToFilter;
  String? get userTypeFilter => _userTypeFilter;
  int? get userIdFilter => _userIdFilter;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  bool? get unassignedFilter => _unassignedFilter;
  bool? get hasEstimateFilter => _hasEstimateFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  List<EstimateRequestStatus> get statusOptions => _statusOptions;
  List<Map<String, dynamic>> get staffMembers => _staffMembers;
  Map<String, dynamic> get requestSettings => _requestSettings;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load estimate requests
  Future<void> loadEstimateRequests({bool refresh = false}) async {
    if (refresh || _estimateRequests.isEmpty) {
      _currentPage = 1;
      _hasMoreData = true;
      _estimateRequests.clear();
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = _buildQueryParams();
      final response = await _apiService.get('/estimate-requests', params: params);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> requestsJson = data['estimate_requests'] ?? [];
        
        final newRequests = requestsJson
            .map((json) => EstimateRequest.fromJson(json))
            .toList();

        if (refresh || _currentPage == 1) {
          _estimateRequests = newRequests;
        } else {
          _estimateRequests.addAll(newRequests);
        }

        // Update pagination info
        final pagination = data['pagination'] ?? {};
        _currentPage = pagination['current_page'] ?? 1;
        _lastPage = pagination['last_page'] ?? 1;
        _totalRequests = pagination['total'] ?? 0;
        _hasMoreData = _currentPage < _lastPage;
      } else {
        _error = response['message'] ?? 'Failed to load estimate requests';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more estimate requests for pagination
  Future<void> loadMoreEstimateRequests() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final params = _buildQueryParams();
      final response = await _apiService.get('/estimate-requests', params: params);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> requestsJson = data['estimate_requests'] ?? [];
        
        final newRequests = requestsJson
            .map((json) => EstimateRequest.fromJson(json))
            .toList();

        _estimateRequests.addAll(newRequests);

        // Update pagination info
        final pagination = data['pagination'] ?? {};
        _currentPage = pagination['current_page'] ?? _currentPage;
        _lastPage = pagination['last_page'] ?? 1;
        _hasMoreData = _currentPage < _lastPage;
      }
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _error = 'Failed to load more requests: ${e.toString()}';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Get single estimate request
  Future<void> getEstimateRequest(int id) async {
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/estimate-requests/$id');

      if (response['success'] == true) {
        _selectedEstimateRequest = EstimateRequest.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Failed to load estimate request';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoadingDetails = false;
    notifyListeners();
  }

  // Create estimate request
  Future<bool> createEstimateRequest(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/estimate-requests', data);

      if (response['success'] == true) {
        await loadEstimateRequests(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create estimate request';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update estimate request
  Future<bool> updateEstimateRequest(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/estimate-requests/$id', data);

      if (response['success'] == true) {
        await loadEstimateRequests(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update estimate request';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Delete estimate request
  Future<bool> deleteEstimateRequest(int id) async {
    try {
      final response = await _apiService.delete('/estimate-requests/$id');

      if (response['success'] == true) {
        _estimateRequests.removeWhere((request) => request.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete estimate request';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Assign staff to estimate request
  Future<bool> assignStaff(int requestId, int staffId) async {
    try {
      final response = await _apiService.post('/estimate-requests/$requestId/assign-staff', {
        'staff_id': staffId,
      });

      if (response['success'] == true) {
        await loadEstimateRequests(refresh: true);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to assign staff';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Change status
  Future<bool> changeStatus(int requestId, int statusId) async {
    try {
      final response = await _apiService.post('/estimate-requests/$requestId/change-status', {
        'status_id': statusId,
      });

      if (response['success'] == true) {
        await loadEstimateRequests(refresh: true);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to change status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.get('/estimate-requests/statistics');

      if (response['success'] == true) {
        _statistics = response['data'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for statistics
    }
  }

  // Load form data
  Future<void> loadFormData() async {
    try {
      final response = await _apiService.get('/estimate-requests/form-data');

      if (response['success'] == true) {
        final data = response['data'];
        
        // Load status options
        final List<dynamic> statusJson = data['status_options'] ?? [];
        _statusOptions = statusJson
            .map((json) => EstimateRequestStatus.fromJson(json))
            .toList();

        // Load staff members
        _staffMembers = List<Map<String, dynamic>>.from(data['staff_members'] ?? []);

        notifyListeners();
      }
    } catch (e) {
      // Silently fail for form data
    }
  }

  // Load request settings
  Future<void> loadRequestSettings() async {
    try {
      final response = await _apiService.get('/estimate-requests/settings');

      if (response['success'] == true) {
        _requestSettings = response['data'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for settings
    }
  }

  // Search
  void searchEstimateRequests(String query) {
    _searchQuery = query;
    loadEstimateRequests(refresh: true);
  }

  // Filters
  void filterByStatus(int? statusId) {
    _statusFilter = statusId;
    loadEstimateRequests(refresh: true);
  }

  void filterByAssignedTo(int? staffId) {
    _assignedToFilter = staffId;
    loadEstimateRequests(refresh: true);
  }

  void filterByUserType(String? userType) {
    _userTypeFilter = userType;
    loadEstimateRequests(refresh: true);
  }

  void filterByDateRange(String? startDate, String? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    loadEstimateRequests(refresh: true);
  }

  void filterUnassigned(bool? unassigned) {
    _unassignedFilter = unassigned;
    loadEstimateRequests(refresh: true);
  }

  void filterByEstimate(bool? hasEstimate) {
    _hasEstimateFilter = hasEstimate;
    loadEstimateRequests(refresh: true);
  }

  // Sorting
  void sortBy(String field, String order) {
    _sortBy = field;
    _sortOrder = order;
    loadEstimateRequests(refresh: true);
  }

  // Build query parameters
  Map<String, dynamic> _buildQueryParams() {
    final params = <String, dynamic>{
      'page': _currentPage,
      'per_page': 20,
      'sort_by': _sortBy,
      'sort_order': _sortOrder,
    };

    if (_searchQuery.isNotEmpty) {
      params['search'] = _searchQuery;
    }

    if (_statusFilter != null) {
      params['status_id'] = _statusFilter;
    }

    if (_assignedToFilter != null) {
      params['assigned_to'] = _assignedToFilter;
    }

    if (_userTypeFilter != null) {
      params['user_type'] = _userTypeFilter;
    }

    if (_userIdFilter != null) {
      params['user_id'] = _userIdFilter;
    }

    if (_startDate != null) {
      params['start_date'] = _startDate;
    }

    if (_endDate != null) {
      params['end_date'] = _endDate;
    }

    if (_unassignedFilter == true) {
      params['unassigned'] = true;
    }

    if (_hasEstimateFilter != null) {
      params['has_estimate'] = _hasEstimateFilter;
    }

    return params;
  }

  // Refresh data
  Future<void> refreshEstimateRequests() async {
    await loadEstimateRequests(refresh: true);
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _assignedToFilter = null;
    _userTypeFilter = null;
    _userIdFilter = null;
    _startDate = null;
    _endDate = null;
    _unassignedFilter = null;
    _hasEstimateFilter = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    loadEstimateRequests(refresh: true);
  }

  // Helper methods
  String formatCurrency(dynamic value) {
    if (value == null) return '\$0.00';
    final amount = double.tryParse(value.toString()) ?? 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color getStatusColor(String? status) {
    if (status == null) return const Color(0xFF95A5A6);
    
    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return const Color(0xFF3498DB);
      case 'in_progress':
      case 'processing':
        return const Color(0xFFF39C12);
      case 'completed':
      case 'done':
        return const Color(0xFF27AE60);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}