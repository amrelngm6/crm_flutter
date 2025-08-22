import 'package:flutter/material.dart';
import '../models/lead.dart';
import '../services/api_service.dart';
import '../models/status.dart';

class LeadsProvider with ChangeNotifier {
  static final LeadsProvider _instance = LeadsProvider._internal();
  factory LeadsProvider() => _instance;
  LeadsProvider._internal();

  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _statistics;

  // Leads state
  List<Lead> _leads = [];
  List<Status> _statusOptions = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Search and filter
  String _searchQuery = '';
  String? _statusFilter;

  // Getters
  List<Lead> get leads => _leads;
  List<Status> get statusOptions => _statusOptions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  Map<String, dynamic>? get statistics => _statistics;

  // Load leads from API
  Future<void> loadLeads({bool forceRefresh = false}) async {
    if (!forceRefresh && _leads.isNotEmpty && _lastUpdated != null) {
      final difference = DateTime.now().difference(_lastUpdated!);
      if (difference.inMinutes < 0) {
        // Data is fresh, no need to reload
        return;
      }
    }

    try {
      _setLoading(true);
      _setError(null);
      _currentPage = 1;
      _hasMoreData = true;

      final response = await _apiService.getLeads(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status_id: _statusFilter,
      );

      print('API Response: ${response['data']}');

      if (response['success'] == true && response['data'] != null) {
        final responseData = response['data'];

        // Handle different response structures
        List<dynamic> leadsJson;
        if (responseData['leads'] != null) {
          // If leads are nested under 'leads' key
          leadsJson = responseData['leads'] as List<dynamic>;
        } else if (responseData['data'] != null) {
          // If leads are nested under 'data' key
          leadsJson = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // If response data is directly a list
          leadsJson = responseData;
        } else {
          leadsJson = [];
        }

        try {
          _leads = leadsJson.map((json) {
            return Lead.fromJson(json);
          }).toList();
        } catch (e) {
          print('Error parsing leads: $e');
          // Print the first lead structure for debugging
          if (leadsJson.isNotEmpty) {
            print('First lead structure: ${leadsJson.first}');
          }
          rethrow;
        }

        // Check if there are more pages
        final meta = responseData['pagination'] ?? responseData['meta'];
        if (meta != null) {
          _hasMoreData = meta['current_page'] < meta['last_page'];
        } else {
          _hasMoreData = leadsJson.length >= 20; // Default page size
        }

        print('Status List: ${responseData['status_list']}');

        // Load status options from Leads request
        _statusOptions = (responseData['status_list'] as List<dynamic>?)
                ?.map((statusJson) => Status.fromJson(statusJson))
                .toList() ??
            [];

        // Handle the status list
        _statusFilter = responseData['status'] ?? 'All';

        _lastUpdated = DateTime.now();
        _setError(null);
      } else {
        throw Exception(response['message'] ?? 'Failed to load leads');
      }
    } catch (e) {
      if (e is TypeError) {
        print('Type error details: ${e.toString()}');
      }
      _setError(e.toString());
      // Use mock data if API fails in development
      await _loadMockData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStatistics() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.getLeadStatistics();

      if (response['success'] == true && response['data'] != null) {
        _statistics = response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to load statistics');
      }
    } catch (e) {
      if (e is TypeError) {
        print('Type error details: ${e.toString()}');
      }
      _setError(e.toString());
      // Use mock data if API fails in development
      await _loadMockData();
    } finally {
      _setLoading(false);
    }
  }

  // Load more leads (pagination)
  Future<void> loadMoreLeads() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final response = await _apiService.getLeads(
        page: _currentPage + 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status_id: _statusFilter,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> leadsJson =
            response['data']['data'] ?? response['data'];
        final newLeads = leadsJson.map((json) => Lead.fromJson(json)).toList();

        _leads.addAll(newLeads);
        _currentPage++;

        // Check if there are more pages
        final meta = response['data']['pagination'];
        if (meta != null) {
          _hasMoreData = meta['current_page'] < meta['last_page'];
        } else {
          _hasMoreData = newLeads.length >= 20; // Default page size
        }
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Search leads
  Future<void> searchLeads(String query) async {
    _searchQuery = query;
    await loadLeads(forceRefresh: true);
  }

  // Filter by status
  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;
    await loadLeads(forceRefresh: true);
  }

  // Refresh leads
  Future<void> refreshLeads() async {
    await loadLeads(forceRefresh: true);
  }

  // Clear leads data
  void clearLeads() {
    _leads = [];
    _error = null;
    _lastUpdated = null;
    _currentPage = 1;
    _hasMoreData = true;
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  // Create new lead
  Future<bool> createLead(Map<String, dynamic> leadData) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.createLead(leadData);

      if (response['success'] == true) {
        // Refresh the leads list
        await loadLeads(forceRefresh: true);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to create lead');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update lead
  Future<bool> updateLead(int id, Map<String, dynamic> leadData) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.updateLead(id, leadData);

      if (response['success'] == true) {
        // Update the lead in the local list
        final index = _leads.indexWhere((lead) => lead.id == id);
        if (index != -1) {
          final updatedLead = Lead.fromJson(response['data']);
          _leads[index] = updatedLead;
          notifyListeners();
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to update lead');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete lead
  Future<bool> deleteLead(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.deleteLead(id);

      if (response['success'] == true) {
        // Remove the lead from the local list
        _leads.removeWhere((lead) => lead.id == id);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to delete lead');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load mock data for development/testing
  Future<void> _loadMockData() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _leads = [
      Lead(
        id: 1,
        name: 'John Doe',
        email: 'john.doe@techcorp.com',
        phone: '+1 (555) 123-4567',
        company: 'Tech Corp Inc.',
        source: 'Website',
        status: 'new',
        value: 15000.0,
        notes: 'Interested in enterprise solution. Follow up next week.',
        assignedTo: 1,
        followUpDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Lead(
        id: 2,
        name: 'Jane Smith',
        email: 'jane.smith@innovate.com',
        phone: '+1 (555) 987-6543',
        company: 'Innovate Solutions',
        source: 'Referral',
        status: 'contacted',
        value: 25000.0,
        notes: 'Very interested. Scheduled demo for next Tuesday.',
        assignedTo: 1,
        followUpDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Lead(
        id: 3,
        name: 'Michael Johnson',
        email: 'm.johnson@startupxyz.com',
        phone: '+1 (555) 456-7890',
        company: 'StartupXYZ',
        source: 'LinkedIn',
        status: 'qualified',
        value: 8500.0,
        notes: 'Budget approved. Ready to move forward.',
        assignedTo: 2,
        followUpDate: DateTime.now().add(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Lead(
        id: 4,
        name: 'Sarah Wilson',
        email: 'sarah.w@globalcorp.com',
        phone: '+1 (555) 234-5678',
        company: 'Global Corp',
        source: 'Trade Show',
        status: 'converted',
        value: 50000.0,
        notes:
            'Successfully converted to client. Great partnership opportunity.',
        assignedTo: 1,
        followUpDate: null,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Lead(
        id: 5,
        name: 'David Brown',
        email: 'david.brown@techstart.io',
        phone: '+1 (555) 345-6789',
        company: 'TechStart.io',
        source: 'Cold Email',
        status: 'new',
        value: 12000.0,
        notes: 'Initial contact made. Needs more information about pricing.',
        assignedTo: 3,
        followUpDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    _lastUpdated = DateTime.now();
    _hasMoreData = false; // No more mock data
  }

  // Helper methods to update state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFF2196F3); // Blue
      case 'contacted':
        return const Color(0xFFFF9800); // Orange
      case 'qualified':
        return const Color(0xFF4CAF50); // Green
      case 'converted':
        return const Color(0xFF9C27B0); // Purple
      case 'lost':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.fiber_new;
      case 'contacted':
        return Icons.phone;
      case 'qualified':
        return Icons.check_circle;
      case 'converted':
        return Icons.star;
      case 'lost':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Format currency
  String formatCurrency(double? amount) {
    if (amount == null) return '\$0';
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  // Format time ago
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
