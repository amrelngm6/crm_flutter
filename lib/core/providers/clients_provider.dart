import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/api_service.dart';
import '../models/status.dart';

class ClientsProvider with ChangeNotifier {
  static final ClientsProvider _instance = ClientsProvider._internal();
  factory ClientsProvider() => _instance;
  ClientsProvider._internal();

  final ApiService _apiService = ApiService();

  // Clients state
  List<Client> _clients = [];
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
  List<Client> get clients => _clients;
  List<Status> get statusOptions => _statusOptions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;

  // Load clients from API
  Future<void> loadClients({bool forceRefresh = false}) async {
    if (!forceRefresh && _clients.isNotEmpty && _lastUpdated != null) {
      final difference = DateTime.now().difference(_lastUpdated!);
      if (difference.inMinutes < 5) {
        // Data is fresh, no need to reload
        return;
      }
    }

    try {
      _setLoading(true);
      _setError(null);
      _currentPage = 1;
      _hasMoreData = true;

      final response = await _apiService.getClients(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
      );

      print('Clients API Response: ${response['data']}');

      if (response['success'] == true && response['data'] != null) {
        final responseData = response['data'];

        // Handle different response structures
        List<dynamic> clientsJson;
        if (responseData['clients'] != null) {
          // If clients are nested under 'clients' key
          clientsJson = responseData['clients'] as List<dynamic>;
        } else if (responseData['data'] != null) {
          // If clients are nested under 'data' key
          clientsJson = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // If response data is directly a list
          clientsJson = responseData;
        } else {
          clientsJson = [];
        }

        try {
          _clients = clientsJson.map((json) {
            return Client.fromJson(json);
          }).toList();
        } catch (e) {
          print('Error parsing clients: $e');
          // Print the first client structure for debugging
          if (clientsJson.isNotEmpty) {
            print('First client structure: ${clientsJson.first}');
          }
          rethrow;
        }

        // Check if there are more pages
        final meta = responseData['pagination'] ?? responseData['meta'];
        if (meta != null) {
          _hasMoreData = meta['current_page'] < meta['last_page'];
        } else {
          _hasMoreData = clientsJson.length >= 20; // Default page size
        }

        // Load status options - add default statuses
        _statusOptions = [
          Status(id: -1, name: 'All', color: '#6c757d'),
          Status(id: 0, name: 'Pending', color: '#ffc107'),
          Status(id: 1, name: 'Active', color: '#28a745'),
        ];

        _lastUpdated = DateTime.now();
        _setError(null);
      } else {
        throw Exception(response['message'] ?? 'Failed to load clients');
      }
    } catch (e) {
      print('Error loading clients: $e');
      print('Error type: ${e.runtimeType}');
      _setError(e.toString());
      // Use mock data if API fails in development
      await _loadMockData();
    } finally {
      _setLoading(false);
    }
  }

  // Load more clients (pagination)
  Future<void> loadMoreClients() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final response = await _apiService.getClients(
        page: _currentPage + 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> clientsJson = response['data']['clients'] ??
            response['data']['data'] ??
            response['data'];
        final newClients =
            clientsJson.map((json) => Client.fromJson(json)).toList();

        _clients.addAll(newClients);
        _currentPage++;

        // Check if there are more pages
        final meta = response['data']['pagination'];
        if (meta != null) {
          _hasMoreData = meta['current_page'] < meta['last_page'];
        } else {
          _hasMoreData = newClients.length >= 20; // Default page size
        }
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Search clients
  Future<void> searchClients(String query) async {
    _searchQuery = query;
    await loadClients(forceRefresh: true);
  }

  // Filter by status
  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;
    await loadClients(forceRefresh: true);
  }

  // Refresh clients
  Future<void> refreshClients() async {
    await loadClients(forceRefresh: true);
  }

  // Clear clients data
  void clearClients() {
    _clients = [];
    _error = null;
    _lastUpdated = null;
    _currentPage = 1;
    _hasMoreData = true;
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  // Create new client
  Future<bool> createClient(Map<String, dynamic> clientData) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.createClient(clientData);

      if (response['success'] == true) {
        // Refresh the clients list
        await loadClients(forceRefresh: true);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to create client');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update client
  Future<bool> updateClient(int id, Map<String, dynamic> clientData) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.updateClient(id, clientData);

      if (response['success'] == true) {
        // Update the client in the local list
        final index = _clients.indexWhere((client) => client.id == id);
        if (index != -1) {
          final updatedClient = Client.fromJson(response['data']);
          _clients[index] = updatedClient;
          notifyListeners();
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to update client');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete client
  Future<bool> deleteClient(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.deleteClient(id);

      if (response['success'] == true) {
        // Remove the client from the local list
        _clients.removeWhere((client) => client.id == id);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to delete client');
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

    _clients = [
      Client(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        name: 'John Doe',
        email: 'john.doe@techcorp.com',
        phone: '+1 (555) 123-4567',
        company: 'Tech Corp Inc.',
        position: 'CEO',
        address: '123 Tech Street',
        city: 'San Francisco',
        state: 'CA',
        country: 'USA',
        postalCode: '94105',
        website: 'https://techcorp.com',
        status: 'active',
        projectsCount: 3,
        invoicesCount: 8,
        totalInvoiced: 45000.0,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Client(
        id: 2,
        firstName: 'Jane',
        lastName: 'Smith',
        name: 'Jane Smith',
        email: 'jane.smith@innovate.com',
        phone: '+1 (555) 987-6543',
        company: 'Innovate Solutions',
        position: 'CTO',
        address: '456 Innovation Ave',
        city: 'New York',
        state: 'NY',
        country: 'USA',
        postalCode: '10001',
        website: 'https://innovate.com',
        status: 'active',
        projectsCount: 5,
        invoicesCount: 12,
        totalInvoiced: 78000.0,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Client(
        id: 3,
        firstName: 'Michael',
        lastName: 'Johnson',
        name: 'Michael Johnson',
        email: 'm.johnson@startupxyz.com',
        phone: '+1 (555) 456-7890',
        company: 'StartupXYZ',
        position: 'Founder',
        address: '789 Startup Blvd',
        city: 'Austin',
        state: 'TX',
        country: 'USA',
        postalCode: '73301',
        status: 'pending',
        projectsCount: 1,
        invoicesCount: 2,
        totalInvoiced: 12000.0,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Client(
        id: 4,
        firstName: 'Sarah',
        lastName: 'Wilson',
        name: 'Sarah Wilson',
        email: 'sarah.w@globalcorp.com',
        phone: '+1 (555) 234-5678',
        company: 'Global Corp',
        position: 'VP Marketing',
        address: '321 Global Plaza',
        city: 'Chicago',
        state: 'IL',
        country: 'USA',
        postalCode: '60601',
        website: 'https://globalcorp.com',
        status: 'active',
        projectsCount: 7,
        invoicesCount: 15,
        totalInvoiced: 120000.0,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Client(
        id: 5,
        firstName: 'David',
        lastName: 'Brown',
        name: 'David Brown',
        email: 'david.brown@techstart.io',
        phone: '+1 (555) 345-6789',
        company: 'TechStart.io',
        position: 'Product Manager',
        address: '654 Tech Park',
        city: 'Seattle',
        state: 'WA',
        country: 'USA',
        postalCode: '98101',
        status: 'inactive',
        projectsCount: 0,
        invoicesCount: 3,
        totalInvoiced: 8500.0,
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
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
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
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
