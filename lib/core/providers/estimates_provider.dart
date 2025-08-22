import 'package:flutter/foundation.dart';
import '../models/estimate.dart';
import '../services/api_service.dart';

class EstimatesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Estimate> _estimates = [];
  List<Estimate> _filteredEstimates = [];
  List<EstimateStatus> _statuses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String? _selectedStatusId;
  String? _selectedApprovalStatus;
  Map<String, dynamic>? _statistics;

  // Getters
  List<Estimate> get estimates => _filteredEstimates;
  List<EstimateStatus> get statuses => _statuses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get selectedStatusId => _selectedStatusId;
  String? get selectedApprovalStatus => _selectedApprovalStatus;
  Map<String, dynamic>? get statistics => _statistics;

  // Statistics getters
  int get totalEstimates => _statistics?['overview']?['total_estimates'] ?? 0;
  double get totalValue => (num.tryParse(
              _statistics?['overview']?['total_value']?.toString() ?? '') ??
          0)
      .toDouble();
  int get convertedCount => _statistics?['overview']?['converted_count'] ?? 0;
  double get conversionRate =>
      (_statistics?['overview']?['conversion_rate'] ?? 0).toDouble();
  double get averageValue =>
      (_statistics?['overview']?['average_value'] ?? 0).toDouble();

  // Approval status counts
  int get pendingCount => estimates.where((e) => e.approval.isPending).length;
  int get approvedCount => estimates.where((e) => e.approval.isApproved).length;
  int get rejectedCount => estimates.where((e) => e.approval.isRejected).length;

  // Status counts
  int get expiredCount => estimates.where((e) => e.dates.isExpired).length;
  int get convertedEstimatesCount =>
      estimates.where((e) => e.conversion.isConverted).length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadEstimates({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _estimates.clear();
      _filteredEstimates.clear();
    }

    if (_isLoading || !_hasMoreData) return;

    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getEstimates(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        statusId:
            _selectedStatusId != null ? int.tryParse(_selectedStatusId!) : null,
        approvalStatus: _selectedApprovalStatus,
      );

      if (response['success'] == true) {
        final estimatesData = response['data']['estimates'] as List;
        final newEstimates =
            estimatesData.map((json) => Estimate.fromJson(json)).toList();

        if (refresh) {
          _estimates = newEstimates;
        } else {
          _estimates.addAll(newEstimates);
        }

        _filteredEstimates = List.from(_estimates);

        final pagination = response['data']['pagination'];
        _hasMoreData = pagination['current_page'] < pagination['last_page'];
        _currentPage++;
      } else {
        _setError(response['message'] ?? 'Failed to load estimates');
      }
    } catch (e) {
      print('Error loading estimates: $e');
      _setError('Error loading estimates: ${e.toString()}');

      // Fallback to mock data for development
      if (_estimates.isEmpty) {
        _loadMockEstimates();
      }
    }

    _setLoading(false);
  }

  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getEstimateStatistics();
      if (response['success'] == true) {
        _statistics = response['data'];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading statistics: $e');
      _loadMockStatistics();
    }
  }

  Future<void> searchEstimates(String query) async {
    _searchQuery = query;
    await loadEstimates(refresh: true);
  }

  Future<void> filterByStatus(String? statusId) async {
    _selectedStatusId = statusId;
    await loadEstimates(refresh: true);
  }

  Future<void> filterByApprovalStatus(String? approvalStatus) async {
    _selectedApprovalStatus = approvalStatus;
    await loadEstimates(refresh: true);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatusId = null;
    _selectedApprovalStatus = null;
    loadEstimates(refresh: true);
  }

  Future<Estimate?> getEstimate(int id) async {
    try {
      final response = await _apiService.getEstimate(id);
      if (response['success'] == true) {
        return Estimate.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting estimate: $e');
      return null;
    }
  }

  Future<bool> createEstimate(Map<String, dynamic> estimateData) async {
    try {
      _setLoading(true);
      final response = await _apiService.createEstimate(estimateData);

      if (response['success'] == true) {
        await loadEstimates(refresh: true);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to create estimate');
        return false;
      }
    } catch (e) {
      print('Error creating estimate: $e');
      _setError('Error creating estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEstimate(int id, Map<String, dynamic> estimateData) async {
    try {
      _setLoading(true);
      final response = await _apiService.updateEstimate(id, estimateData);

      if (response['success'] == true) {
        await loadEstimates(refresh: true);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update estimate');
        return false;
      }
    } catch (e) {
      print('Error updating estimate: $e');
      _setError('Error updating estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteEstimate(int id) async {
    try {
      _setLoading(true);
      final response = await _apiService.deleteEstimate(id);

      if (response['success'] == true) {
        _estimates.removeWhere((estimate) => estimate.id == id);
        _filteredEstimates.removeWhere((estimate) => estimate.id == id);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to delete estimate');
        return false;
      }
    } catch (e) {
      print('Error deleting estimate: $e');
      _setError('Error deleting estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> convertToInvoice(int id) async {
    try {
      _setLoading(true);
      final response = await _apiService.convertEstimateToInvoice(id);

      if (response['success'] == true) {
        await loadEstimates(refresh: true);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to convert estimate');
        return false;
      }
    } catch (e) {
      print('Error converting estimate: $e');
      _setError('Error converting estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveEstimate(int id) async {
    try {
      _setLoading(true);
      final response = await _apiService.approveEstimate(id);

      if (response['success'] == true) {
        await loadEstimates(refresh: true);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to approve estimate');
        return false;
      }
    } catch (e) {
      print('Error approving estimate: $e');
      _setError('Error approving estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectEstimate(int id) async {
    try {
      _setLoading(true);
      final response = await _apiService.rejectEstimate(id);

      if (response['success'] == true) {
        await loadEstimates(refresh: true);
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to reject estimate');
        return false;
      }
    } catch (e) {
      print('Error rejecting estimate: $e');
      _setError('Error rejecting estimate: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _loadMockEstimates() {
    _estimates = [
      Estimate(
        id: 1,
        estimateNumber: 'EST-001',
        title: 'Website Development Estimate',
        content: 'Complete website development with modern design',
        status: EstimateStatus(id: 1, name: 'Draft', color: '#6c757d'),
        approval: EstimateApproval(
          status: 'pending',
          requiresApproval: true,
          isApproved: false,
          isRejected: false,
          isPending: true,
        ),
        dates: EstimateDates(
          date: DateTime.now().subtract(const Duration(days: 2)),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          isExpired: false,
          daysUntilExpiry: 30,
          convertedAt: null,
        ),
        financial: EstimateFinancial(
          currencyCode: 'USD',
          subtotal: 5000.00,
          discountAmount: 250.00,
          taxAmount: 475.00,
          total: 5225.00,
          formattedTotal: '\$5,225.00',
        ),
        conversion: EstimateConversion(
          convertedToInvoice: false,
          isConverted: false,
          invoiceId: null,
          invoice: null,
        ),
        client: EstimateClient(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          companyName: 'Tech Solutions Inc.',
          avatar: null,
        ),
        assignedTo: EstimateAssignedTo(
          id: 1,
          name: 'Sarah Johnson',
          email: 'sarah@company.com',
          avatar: null,
        ),
        model: EstimateModel(
          id: 1,
          type: 'Project',
          name: 'Web Development Project',
          details: EstimateModelDetails(
            name: 'Web Development Project',
            title: 'Complete Website Solution',
          ),
        ),
        items: EstimateItems(
          count: 3,
          items: [
            EstimateItem(
              id: 1,
              itemName: 'Frontend Development',
              description: 'React.js frontend development',
              quantity: 1,
              unitPrice: 3000.00,
              subtotal: 3000.00,
              tax: 10.0,
              total: 3300.00,
              itemId: null,
              itemType: 'service',
            ),
            EstimateItem(
              id: 2,
              itemName: 'Backend Development',
              description: 'Node.js backend development',
              quantity: 1,
              unitPrice: 2000.00,
              subtotal: 2000.00,
              tax: 10.0,
              total: 2200.00,
              itemId: null,
              itemType: 'service',
            ),
          ],
        ),
        requests: null,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Estimate(
        id: 2,
        estimateNumber: 'EST-002',
        title: 'Mobile App Development',
        content: 'iOS and Android mobile application',
        status: EstimateStatus(id: 2, name: 'Sent', color: '#007bff'),
        approval: EstimateApproval(
          status: 'approved',
          requiresApproval: true,
          isApproved: true,
          isRejected: false,
          isPending: false,
        ),
        dates: EstimateDates(
          date: DateTime.now().subtract(const Duration(days: 5)),
          expiryDate: DateTime.now().add(const Duration(days: 25)),
          isExpired: false,
          daysUntilExpiry: 25,
          convertedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        financial: EstimateFinancial(
          currencyCode: 'USD',
          subtotal: 8000.00,
          discountAmount: 400.00,
          taxAmount: 760.00,
          total: 8360.00,
          formattedTotal: '\$8,360.00',
        ),
        conversion: EstimateConversion(
          convertedToInvoice: true,
          isConverted: true,
          invoiceId: 1,
          invoice: EstimateInvoice(
            id: 1,
            invoiceNumber: 'INV-001',
            status: 'sent',
          ),
        ),
        client: EstimateClient(
          id: 2,
          name: 'Jane Smith',
          email: 'jane@startup.com',
          phone: '+1987654321',
          companyName: 'Startup Innovations',
          avatar: null,
        ),
        assignedTo: EstimateAssignedTo(
          id: 2,
          name: 'Mike Chen',
          email: 'mike@company.com',
          avatar: null,
        ),
        model: EstimateModel(
          id: 2,
          type: 'Project',
          name: 'Mobile App Project',
          details: EstimateModelDetails(
            name: 'Mobile App Project',
            title: 'Cross-Platform Mobile Solution',
          ),
        ),
        items: EstimateItems(
          count: 2,
          items: [
            EstimateItem(
              id: 3,
              itemName: 'iOS Development',
              description: 'Native iOS app development',
              quantity: 1,
              unitPrice: 4000.00,
              subtotal: 4000.00,
              tax: 10.0,
              total: 4400.00,
              itemId: null,
              itemType: 'service',
            ),
            EstimateItem(
              id: 4,
              itemName: 'Android Development',
              description: 'Native Android app development',
              quantity: 1,
              unitPrice: 4000.00,
              subtotal: 4000.00,
              tax: 10.0,
              total: 4400.00,
              itemId: null,
              itemType: 'service',
            ),
          ],
        ),
        requests: null,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    _filteredEstimates = List.from(_estimates);
    notifyListeners();
  }

  void _loadMockStatistics() {
    _statistics = {
      'overview': {
        'total_estimates': 25,
        'total_value': 125000.0,
        'converted_count': 18,
        'conversion_rate': 72.0,
        'average_value': 5000.0,
      },
    };
    notifyListeners();
  }
}
