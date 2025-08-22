import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../services/api_service.dart';

class DealsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Deal> _deals = [];
  List<Deal> _filteredDeals = [];
  List<Map<String, dynamic>> _pipelines = [];
  List<Map<String, dynamic>> _stages = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _leads = [];
  Map<String, dynamic>? _statistics;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _perPage = 20;

  String _searchQuery = '';
  int? _selectedPipelineId;
  int? _selectedStageId;
  String? _selectedStatus;

  // Getters
  List<Deal> get deals =>
      _filteredDeals.isEmpty && _searchQuery.isEmpty ? _deals : _filteredDeals;
  List<Map<String, dynamic>> get pipelines => _pipelines;
  List<Map<String, dynamic>> get stages => _stages;
  List<Map<String, dynamic>> get clients => _clients;
  List<Map<String, dynamic>> get leads => _leads;
  Map<String, dynamic>? get statistics => _statistics;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMorePages => _currentPage < _totalPages;

  String get searchQuery => _searchQuery;
  int? get selectedPipelineId => _selectedPipelineId;
  int? get selectedStageId => _selectedStageId;
  String? get selectedStatus => _selectedStatus;

  // Mock data for fallback
  static const List<Map<String, dynamic>> _mockDeals = [
    {
      'id': 1,
      'name': 'Website Redesign Project',
      'code': 'DEL-001',
      'description':
          'Complete website redesign for ABC Corp including mobile optimization',
      'amount': {
        'value': 15000.0,
        'currency_code': 'USD',
        'formatted': '\$15,000.00'
      },
      'probability': 75.0,
      'expected_due_date': '2025-09-15',
      'status': 'negotiation',
      'contact_info': {'email': 'john@abccorp.com', 'phone': '+1-555-0123'},
      'client': {
        'id': 1,
        'name': 'ABC Corporation',
        'email': 'contact@abccorp.com',
        'phone': '+1-555-0100',
        'company_name': 'ABC Corp',
        'avatar': 'images/1.png'
      },
      'stage': {
        'id': 3,
        'name': 'Negotiation',
        'color': '#f39c12',
        'probability': 75.0,
        'pipeline': {'id': 1, 'name': 'Sales Pipeline'}
      },
      'team': [
        {
          'id': 1,
          'user_type': 'staff',
          'name': 'John Smith',
          'email': 'john@company.com',
          'avatar': 'images/avatar-1.jpg'
        }
      ],
      'author': {
        'id': 1,
        'name': 'Sales Manager',
        'email': 'sales@company.com'
      },
      'tasks': {'count': 5, 'completed': 3, 'pending': 2},
      'digital_activity': {
        'has_activity': true,
        'recent_visits_count': 12,
        'recent_submissions_count': 3
      },
      'business_id': 1,
      'created_by': 1,
      'created_at': '2025-08-10T10:00:00Z',
      'updated_at': '2025-08-15T14:30:00Z'
    },
    {
      'id': 2,
      'name': 'Mobile App Development',
      'code': 'DEL-002',
      'description':
          'Native iOS and Android app development for e-commerce platform',
      'amount': {
        'value': 35000.0,
        'currency_code': 'USD',
        'formatted': '\$35,000.00'
      },
      'probability': 60.0,
      'expected_due_date': '2025-10-20',
      'status': 'proposal',
      'contact_info': {'email': 'sarah@techstart.com', 'phone': '+1-555-0456'},
      'lead': {
        'id': 5,
        'name': 'Sarah Johnson',
        'email': 'sarah@techstart.com',
        'phone': '+1-555-0456',
        'company_name': 'TechStart Inc',
        'source': 'LinkedIn'
      },
      'stage': {
        'id': 2,
        'name': 'Proposal',
        'color': '#3498db',
        'probability': 60.0,
        'pipeline': {'id': 1, 'name': 'Sales Pipeline'}
      },
      'team': [
        {
          'id': 2,
          'user_type': 'staff',
          'name': 'Mike Wilson',
          'email': 'mike@company.com',
          'avatar': 'images/avatar-2.jpg'
        }
      ],
      'author': {
        'id': 2,
        'name': 'Business Dev',
        'email': 'bizdev@company.com'
      },
      'tasks': {'count': 8, 'completed': 2, 'pending': 6},
      'digital_activity': {
        'has_activity': false,
        'recent_visits_count': 0,
        'recent_submissions_count': 0
      },
      'business_id': 1,
      'created_by': 2,
      'created_at': '2025-08-12T09:15:00Z',
      'updated_at': '2025-08-18T16:45:00Z'
    }
  ];

  static const Map<String, dynamic> _mockStatistics = {
    'total_deals': 45,
    'total_value': 450000.0,
    'won_deals': 12,
    'won_value': 180000.0,
    'pipeline_conversion': 26.7,
    'average_deal_size': 10000.0,
    'deals_by_stage': [
      {'stage': 'Qualified', 'count': 8, 'value': 80000.0},
      {'stage': 'Proposal', 'count': 12, 'value': 120000.0},
      {'stage': 'Negotiation', 'count': 6, 'value': 90000.0},
      {'stage': 'Closed Won', 'count': 12, 'value': 180000.0}
    ]
  };

  // Load deals with optional filters
  Future<void> loadDeals({
    bool refresh = false,
    int? pipelineId,
    int? stageId,
    String? status,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _deals.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getDeals(
        page: _currentPage,
        perPage: _perPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        pipelineId: pipelineId ?? _selectedPipelineId,
        stageId: stageId ?? _selectedStageId,
        status: status ?? _selectedStatus,
      );

      if (response['success'] == true) {
        final List<dynamic> dealsData = response['data']['deals'] ?? [];
        final List<Deal> newDeals =
            dealsData.map((json) => Deal.fromJson(json)).toList();

        if (refresh) {
          _deals = newDeals;
        } else {
          _deals.addAll(newDeals);
        }

        // Update pagination info
        final pagination = response['data']['pagination'] ?? {};
        _currentPage = pagination['current_page'] ?? 1;
        _totalPages = pagination['last_page'] ?? 1;
        _totalItems = pagination['total'] ?? 0;

        _applyFilters();
      } else {
        throw Exception(response['message'] ?? 'Failed to load deals');
      }
    } catch (e) {
      print('Error loading deals: $e');
      // Fallback to mock data
      if (_deals.isEmpty) {
        _deals = _mockDeals.map((json) => Deal.fromJson(json)).toList();
        _applyFilters();
      }
      _setError('Failed to load deals: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Search deals
  Future<void> searchDeals(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredDeals = [];
    } else {
      _filteredDeals = _deals.where((deal) {
        final searchLower = query.toLowerCase();
        return deal.name.toLowerCase().contains(searchLower) ||
            deal.code.toLowerCase().contains(searchLower) ||
            deal.description.toLowerCase().contains(searchLower) ||
            (deal.client?.name?.toLowerCase().contains(searchLower) ?? false) ||
            (deal.lead?.name?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  // Filter by pipeline
  Future<void> filterByPipeline(int? pipelineId) async {
    _selectedPipelineId = pipelineId;
    _currentPage = 1;
    await loadDeals(refresh: true, pipelineId: pipelineId);
  }

  // Filter by stage
  Future<void> filterByStage(int? stageId) async {
    _selectedStageId = stageId;
    _currentPage = 1;
    await loadDeals(refresh: true, stageId: stageId);
  }

  // Filter by status
  Future<void> filterByStatus(String? status) async {
    _selectedStatus = status;
    _currentPage = 1;
    await loadDeals(refresh: true, status: status);
  }

  // Load more deals (pagination)
  Future<void> loadMoreDeals() async {
    if (!_isLoading && hasMorePages) {
      _currentPage++;
      await loadDeals();
    }
  }

  // Load pipelines
  Future<void> loadPipelines() async {
    try {
      final response = await _apiService.getPipelines();
      if (response['success'] == true) {
        _pipelines = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      print('Error loading pipelines: $e');
      // Mock pipelines
      _pipelines = [
        {'id': 1, 'name': 'Sales Pipeline', 'is_default': true},
        {'id': 2, 'name': 'Partner Pipeline', 'is_default': false},
      ];
    }
    notifyListeners();
  }

  // Load pipeline stages
  Future<void> loadPipelineStages({int? pipelineId}) async {
    try {
      final response =
          await _apiService.getPipelineStages(pipelineId: pipelineId);
      if (response['success'] == true) {
        _stages = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      print('Error loading stages: $e');
      // Mock stages
      _stages = [
        {'id': 1, 'name': 'Qualified', 'color': '#2ecc71', 'probability': 25.0},
        {'id': 2, 'name': 'Proposal', 'color': '#3498db', 'probability': 50.0},
        {
          'id': 3,
          'name': 'Negotiation',
          'color': '#f39c12',
          'probability': 75.0
        },
        {
          'id': 4,
          'name': 'Closed Won',
          'color': '#27ae60',
          'probability': 100.0
        },
        {
          'id': 5,
          'name': 'Closed Lost',
          'color': '#e74c3c',
          'probability': 0.0
        },
      ];
    }
    notifyListeners();
  }

  // Load clients for deal creation
  Future<void> loadDealsClients() async {
    try {
      final response = await _apiService.getDealsClients();
      if (response['success'] == true) {
        _clients = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      print('Error loading clients: $e');
    }
    notifyListeners();
  }

  // Load leads for deal creation
  Future<void> loadDealsLeads() async {
    try {
      final response = await _apiService.getDealsLeads();
      if (response['success'] == true) {
        _leads = List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
    } catch (e) {
      print('Error loading leads: $e');
    }
    notifyListeners();
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getDealsStatistics();
      if (response['success'] == true) {
        _statistics = response['data'];
      }
    } catch (e) {
      print('Error loading statistics: $e');
      _statistics = _mockStatistics;
    }
    notifyListeners();
  }

  // Move deal to stage
  Future<bool> moveDealToStage(int dealId, int stageId) async {
    try {
      final response = await _apiService.moveDealToStage(dealId, stageId);
      if (response['success'] == true) {
        // Update the deal in the list
        final dealIndex = _deals.indexWhere((deal) => deal.id == dealId);
        if (dealIndex != -1) {
          await loadDeals(refresh: true); // Refresh to get updated data
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error moving deal to stage: $e');
      _setError('Failed to move deal: ${e.toString()}');
      return false;
    }
  }

  // Create deal
  Future<bool> createDeal(Map<String, dynamic> dealData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createDeal(dealData);
      if (response['success'] == true) {
        await loadDeals(refresh: true);
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to create deal');
    } catch (e) {
      _setError('Failed to create deal: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update deal
  Future<bool> updateDeal(int dealId, Map<String, dynamic> dealData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateDeal(dealId, dealData);
      if (response['success'] == true) {
        await loadDeals(refresh: true);
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to update deal');
    } catch (e) {
      _setError('Failed to update deal: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete deal
  Future<bool> deleteDeal(int dealId) async {
    try {
      final response = await _apiService.deleteDeal(dealId);
      if (response['success'] == true) {
        _deals.removeWhere((deal) => deal.id == dealId);
        _applyFilters();
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to delete deal');
    } catch (e) {
      _setError('Failed to delete deal: ${e.toString()}');
      return false;
    }
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedPipelineId = null;
    _selectedStageId = null;
    _selectedStatus = null;
    _filteredDeals = [];
    notifyListeners();
  }

  // Helper methods
  void _applyFilters() {
    if (_searchQuery.isNotEmpty) {
      searchDeals(_searchQuery);
    } else {
      _filteredDeals = [];
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Get deal value statistics
  Map<String, dynamic> getDealValueStats() {
    if (deals.isEmpty) return {'total': 0.0, 'average': 0.0};

    double total = deals.fold(0.0, (sum, deal) => sum + deal.amount.value);
    double average = total / deals.length;

    return {
      'total': total,
      'average': average,
      'count': deals.length,
    };
  }

  // Get deals by status
  Map<String, int> getDealsByStatus() {
    Map<String, int> statusCount = {};
    for (var deal in deals) {
      statusCount[deal.status] = (statusCount[deal.status] ?? 0) + 1;
    }
    return statusCount;
  }

  // Get high probability deals
  List<Deal> getHighProbabilityDeals({double threshold = 70.0}) {
    return deals.where((deal) => deal.probability >= threshold).toList();
  }
}
