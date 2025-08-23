import 'package:flutter/foundation.dart';
import '../models/estimate_request.dart';
import '../services/api_service.dart';

class EstimateRequestsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estimate Requests
  List<EstimateRequest> _estimateRequests = [];
  EstimateRequest? _selectedEstimateRequest;
  Map<String, dynamic> _statistics = {};
  EstimateRequestFormData? _formData;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isLoadingFormData = false;
  bool _isLoadingStatistics = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _hasMoreData = true;

  // Search and filters
  String _searchQuery = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  int? _statusFilter;
  int? _assignedToFilter;
  String? _priorityFilter;
  String? _sourceFilter;
  String? _startDate;
  String? _endDate;
  bool? _urgentFilter;
  bool? _followUpFilter;

  // Getters
  List<EstimateRequest> get estimateRequests => _estimateRequests;
  EstimateRequest? get selectedEstimateRequest => _selectedEstimateRequest;
  Map<String, dynamic> get statistics => _statistics;
  EstimateRequestFormData? get formData => _formData;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingFormData => _isLoadingFormData;
  bool get isLoadingStatistics => _isLoadingStatistics;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  int? get statusFilter => _statusFilter;
  int? get assignedToFilter => _assignedToFilter;
  String? get priorityFilter => _priorityFilter;
  String? get sourceFilter => _sourceFilter;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  bool? get urgentFilter => _urgentFilter;
  bool? get followUpFilter => _followUpFilter;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetPagination() {
    _currentPage = 1;
    _lastPage = 1;
    _total = 0;
    _hasMoreData = true;
    _estimateRequests.clear();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    resetPagination();
    notifyListeners();
  }

  void setSortBy(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    resetPagination();
    notifyListeners();
  }

  void setStatusFilter(int? statusId) {
    _statusFilter = statusId;
    resetPagination();
    notifyListeners();
  }

  void setAssignedToFilter(int? assignedTo) {
    _assignedToFilter = assignedTo;
    resetPagination();
    notifyListeners();
  }

  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    resetPagination();
    notifyListeners();
  }

  void setSourceFilter(String? source) {
    _sourceFilter = source;
    resetPagination();
    notifyListeners();
  }

  void setDateRange(String? startDate, String? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    resetPagination();
    notifyListeners();
  }

  void setUrgentFilter(bool? urgent) {
    _urgentFilter = urgent;
    resetPagination();
    notifyListeners();
  }

  void setFollowUpFilter(bool? followUp) {
    _followUpFilter = followUp;
    resetPagination();
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _assignedToFilter = null;
    _priorityFilter = null;
    _sourceFilter = null;
    _startDate = null;
    _endDate = null;
    _urgentFilter = null;
    _followUpFilter = null;
    resetPagination();
    notifyListeners();
  }

  // Load estimate requests
  Future<void> loadEstimateRequests({bool refresh = false}) async {
    if (refresh) {
      resetPagination();
    }

    if (!_hasMoreData || _isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'search': _searchQuery,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };

      if (_statusFilter != null) queryParams['status_id'] = _statusFilter;
      if (_assignedToFilter != null) queryParams['assigned_to'] = _assignedToFilter;
      if (_priorityFilter != null) queryParams['priority'] = _priorityFilter;
      if (_sourceFilter != null) queryParams['source'] = _sourceFilter;
      if (_startDate != null) queryParams['start_date'] = _startDate;
      if (_endDate != null) queryParams['end_date'] = _endDate;
      if (_urgentFilter != null) queryParams['is_urgent'] = _urgentFilter;
      if (_followUpFilter != null) queryParams['is_follow_up'] = _followUpFilter;

      final response = await _apiService.get('/estimate-requests', queryParams: queryParams);

      if (response['success'] == true) {
        final data = response['data'];
        final estimateRequests = (data['estimate_requests'] as List<dynamic>)
            .map((e) => EstimateRequest.fromJson(e))
            .toList();

        if (refresh) {
          _estimateRequests = estimateRequests;
        } else {
          _estimateRequests.addAll(estimateRequests);
        }

        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
        _total = data['total'] ?? 0;
        _hasMoreData = _currentPage < _lastPage;

        if (_hasMoreData) {
          _currentPage++;
        }
      } else {
        _error = response['message'] ?? 'Failed to load estimate requests';
      }
    } catch (e) {
      _error = 'Error loading estimate requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load estimate request details
  Future<void> loadEstimateRequestDetails(int id) async {
    try {
      _isLoadingDetails = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/estimate-requests/$id');

      if (response['success'] == true) {
        _selectedEstimateRequest = EstimateRequest.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Failed to load estimate request details';
      }
    } catch (e) {
      _error = 'Error loading estimate request details: $e';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Load form data
  Future<void> loadFormData() async {
    try {
      _isLoadingFormData = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/estimate-requests/form-data');

      if (response['success'] == true) {
        _formData = EstimateRequestFormData.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Failed to load form data';
      }
    } catch (e) {
      _error = 'Error loading form data: $e';
    } finally {
      _isLoadingFormData = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _isLoadingStatistics = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/estimate-requests/statistics');

      if (response['success'] == true) {
        _statistics = response['data'];
      } else {
        _error = response['message'] ?? 'Failed to load statistics';
      }
    } catch (e) {
      _error = 'Error loading statistics: $e';
    } finally {
      _isLoadingStatistics = false;
      notifyListeners();
    }
  }

  // Create estimate request
  Future<bool> createEstimateRequest(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/estimate-requests', data);

      if (response['success'] == true) {
        final newRequest = EstimateRequest.fromJson(response['data']);
        _estimateRequests.insert(0, newRequest);
        _total++;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create estimate request';
        return false;
      }
    } catch (e) {
      _error = 'Error creating estimate request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update estimate request
  Future<bool> updateEstimateRequest(int id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.put('/estimate-requests/$id', data);

      if (response['success'] == true) {
        final updatedRequest = EstimateRequest.fromJson(response['data']);
        
        // Update in the list
        final index = _estimateRequests.indexWhere((r) => r.id == id);
        if (index != -1) {
          _estimateRequests[index] = updatedRequest;
        }

        // Update selected request if it's the same
        if (_selectedEstimateRequest?.id == id) {
          _selectedEstimateRequest = updatedRequest;
        }

        return true;
      } else {
        _error = response['message'] ?? 'Failed to update estimate request';
        return false;
      }
    } catch (e) {
      _error = 'Error updating estimate request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete estimate request
  Future<bool> deleteEstimateRequest(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.delete('/estimate-requests/$id');

      if (response['success'] == true) {
        _estimateRequests.removeWhere((r) => r.id == id);
        _total--;
        
        if (_selectedEstimateRequest?.id == id) {
          _selectedEstimateRequest = null;
        }

        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete estimate request';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting estimate request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign estimate
  Future<bool> assignEstimate(int requestId, int estimateId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/estimate-requests/$requestId/assign-estimate', {
        'estimate_id': estimateId,
      });

      if (response['success'] == true) {
        final updatedRequest = EstimateRequest.fromJson(response['data']);
        
        // Update in the list
        final index = _estimateRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          _estimateRequests[index] = updatedRequest;
        }

        // Update selected request if it's the same
        if (_selectedEstimateRequest?.id == requestId) {
          _selectedEstimateRequest = updatedRequest;
        }

        return true;
      } else {
        _error = response['message'] ?? 'Failed to assign estimate';
        return false;
      }
    } catch (e) {
      _error = 'Error assigning estimate: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign staff
  Future<bool> assignStaff(int requestId, int staffId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/estimate-requests/$requestId/assign-staff', {
        'assigned_to': staffId,
      });

      if (response['success'] == true) {
        final updatedRequest = EstimateRequest.fromJson(response['data']);
        
        // Update in the list
        final index = _estimateRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          _estimateRequests[index] = updatedRequest;
        }

        // Update selected request if it's the same
        if (_selectedEstimateRequest?.id == requestId) {
          _selectedEstimateRequest = updatedRequest;
        }

        return true;
      } else {
        _error = response['message'] ?? 'Failed to assign staff';
        return false;
      }
    } catch (e) {
      _error = 'Error assigning staff: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change status
  Future<bool> changeStatus(int requestId, int statusId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/estimate-requests/$requestId/change-status', {
        'status_id': statusId,
      });

      if (response['success'] == true) {
        final updatedRequest = EstimateRequest.fromJson(response['data']);
        
        // Update in the list
        final index = _estimateRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          _estimateRequests[index] = updatedRequest;
        }

        // Update selected request if it's the same
        if (_selectedEstimateRequest?.id == requestId) {
          _selectedEstimateRequest = updatedRequest;
        }

        return true;
      } else {
        _error = response['message'] ?? 'Failed to change status';
        return false;
      }
    } catch (e) {
      _error = 'Error changing status: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check daily limit
  Future<Map<String, dynamic>> checkDailyLimit() async {
    try {
      final response = await _apiService.get('/estimate-requests/check-daily-limit');
      
      if (response['success'] == true) {
        return response['data'];
      } else {
        return {'can_create': false, 'message': response['message']};
      }
    } catch (e) {
      return {'can_create': false, 'message': 'Error checking daily limit: $e'};
    }
  }

  // Get request settings
  Future<Map<String, dynamic>> getRequestSettings() async {
    try {
      final response = await _apiService.get('/estimate-requests/settings');
      
      if (response['success'] == true) {
        return response['data'];
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
}