import 'package:flutter/foundation.dart';
import '../models/proposal.dart';
import '../services/api_service.dart';

class ProposalsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Proposal> _proposals = [];
  List<ProposalStatus> _statuses = [];
  List<AvailableItem> _availableItems = [];
  List<AvailableItemGroup> _itemGroups = [];

  Proposal? _selectedProposal;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isLoadingItems = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalProposals = 0;
  bool _hasMoreData = true;

  // Search and filter state
  String _searchQuery = '';
  int? _selectedStatusId;
  int? _selectedClientId;
  String? _modelType;
  int? _modelId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _expired;
  bool? _expiringSoon;
  bool? _convertedToInvoice;
  double? _minTotal;
  double? _maxTotal;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  bool _myProposalsOnly = false;

  // Getters
  List<Proposal> get proposals => _proposals;
  List<ProposalStatus> get statuses => _statuses;
  List<AvailableItem> get availableItems => _availableItems;
  List<AvailableItemGroup> get itemGroups => _itemGroups;
  Proposal? get selectedProposal => _selectedProposal;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingItems => _isLoadingItems;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalProposals => _totalProposals;
  bool get hasMoreData => _hasMoreData;

  // Filter getters
  String get searchQuery => _searchQuery;
  int? get selectedStatusId => _selectedStatusId;
  int? get selectedClientId => _selectedClientId;
  String? get modelType => _modelType;
  int? get modelId => _modelId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool? get expired => _expired;
  bool? get expiringSoon => _expiringSoon;
  bool? get convertedToInvoice => _convertedToInvoice;
  double? get minTotal => _minTotal;
  double? get maxTotal => _maxTotal;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get myProposalsOnly => _myProposalsOnly;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize data
  Future<void> initialize() async {
    try {
      await Future.wait([
        loadStatuses(),
        loadProposals(refresh: true),
      ]);
    } catch (e) {
      _error = 'Failed to initialize proposals: ${e.toString()}';
    }
  }

  // Load proposals with pagination and filters
  Future<void> loadProposals({
    bool refresh = false,
    int? page,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _proposals.clear();
    }

    if (!_hasMoreData && !refresh) return;

    final targetPage = page ?? _currentPage;

    if (targetPage == 1 || refresh) {
      _isLoading = true;
    }

    _error = null;
    notifyListeners();

    try {
      late Map<String, dynamic> response;
      response = await _apiService.getProposals(
        page: targetPage,
        perPage: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        statusId: _selectedStatusId,
        clientId: _selectedClientId,
        modelType: _modelType,
        modelId: _modelId,
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        expired: _expired,
        expiringSoon: _expiringSoon,
        convertedToInvoice: _convertedToInvoice,
        minTotal: _minTotal,
        maxTotal: _maxTotal,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        myProposalsOnly: _myProposalsOnly,
      );

      final proposalsData = response['data']['proposals'] as List;
      final newProposals =
          proposalsData.map((json) => Proposal.fromJson(json)).toList();

      if (refresh || targetPage == 1) {
        _proposals = newProposals;
      } else {
        _proposals.addAll(newProposals);
      }

      final pagination = response['data']['pagination'];

      _currentPage = pagination['current_page'] ?? 1;
      _lastPage = pagination['last_page'] ?? 1;
      _totalProposals = pagination['total'] ?? 0;
      _hasMoreData = _currentPage < _lastPage;

      if (_hasMoreData) {
        _currentPage++;
      }

      if (response['data']['items'] != null) {
        final itemsData = response['data']['items'] as List;
        final newItems =
            itemsData.map((json) => AvailableItem.fromJson(json)).toList();
        _availableItems.addAll(newItems);
      }

      // _itemGroups
      if (response['data']['item_groups'] != null) {
        final itemGroupsData = response['data']['item_groups'] as List;
        final newItemGroups = itemGroupsData
            .map((json) => AvailableItemGroup.fromJson(json))
            .toList();
        _itemGroups.addAll(newItemGroups);
      }
    } catch (e) {
      _error = 'Failed to load proposals: ${e.toString()}';
      print('Error loading proposals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (!_hasMoreData || _isLoading) return;
    await loadProposals();
  }

  // Search proposals
  Future<void> searchProposals(String query) async {
    _searchQuery = query;
    await loadProposals(refresh: true);
  }

  // Filter methods
  Future<void> filterByStatus(int? statusId) async {
    _selectedStatusId = statusId;
    await loadProposals(refresh: true);
  }

  Future<void> filterByClient(int? clientId) async {
    _selectedClientId = clientId;
    await loadProposals(refresh: true);
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    await loadProposals(refresh: true);
  }

  Future<void> filterByTotalRange(double? min, double? max) async {
    _minTotal = min;
    _maxTotal = max;
    await loadProposals(refresh: true);
  }

  Future<void> toggleExpiredFilter() async {
    _expired = _expired == true ? null : true;
    await loadProposals(refresh: true);
  }

  Future<void> toggleExpiringSoonFilter() async {
    _expiringSoon = _expiringSoon == true ? null : true;
    await loadProposals(refresh: true);
  }

  Future<void> toggleConvertedFilter() async {
    _convertedToInvoice = _convertedToInvoice == true ? null : true;
    await loadProposals(refresh: true);
  }

  Future<void> toggleMyProposalsOnly() async {
    _myProposalsOnly = !_myProposalsOnly;
    await loadProposals(refresh: true);
  }

  Future<void> setSorting(String sortBy, String sortOrder) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    await loadProposals(refresh: true);
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedStatusId = null;
    _selectedClientId = null;
    _modelType = null;
    _modelId = null;
    _startDate = null;
    _endDate = null;
    _expired = null;
    _expiringSoon = null;
    _convertedToInvoice = null;
    _minTotal = null;
    _maxTotal = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    _myProposalsOnly = false;
    await loadProposals(refresh: true);
  }

  // Load proposal details
  Future<void> loadProposalDetails(int id) async {
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getProposal(id);
      _selectedProposal = Proposal.fromJson(response['data']);
    } catch (e) {
      _error = 'Failed to load proposal details: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading proposal details: $e');
      }
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Create proposal
  Future<bool> createProposal(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createProposal(data);
      final newProposal = Proposal.fromJson(response['data']);

      _proposals.insert(0, newProposal);
      _totalProposals++;

      return true;
    } catch (e) {
      _error = 'Failed to create proposal: ${e.toString()}';
      if (kDebugMode) {
        print('Error creating proposal: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update proposal
  Future<bool> updateProposal(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProposal(id, data);
      final updatedProposal = Proposal.fromJson(response['data']);

      final index = _proposals.indexWhere((p) => p.id == id);
      if (index != -1) {
        _proposals[index] = updatedProposal;
      }

      if (_selectedProposal?.id == id) {
        _selectedProposal = updatedProposal;
      }

      return true;
    } catch (e) {
      _error = 'Failed to update proposal: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating proposal: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete proposal
  Future<bool> deleteProposal(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteProposal(id);

      _proposals.removeWhere((p) => p.id == id);
      _totalProposals--;

      if (_selectedProposal?.id == id) {
        _selectedProposal = null;
      }

      return true;
    } catch (e) {
      _error = 'Failed to delete proposal: ${e.toString()}';
      if (kDebugMode) {
        print('Error deleting proposal: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert proposal to invoice
  Future<bool> convertToInvoice(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.convertProposalToInvoice(id);

      // Update the proposal status if conversion was successful
      final index = _proposals.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Reload the proposal to get updated data
        await loadProposalDetails(id);
      }

      return true;
    } catch (e) {
      _error = 'Failed to convert proposal to invoice: ${e.toString()}';
      if (kDebugMode) {
        print('Error converting proposal: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statuses
  Future<void> loadStatuses() async {
    try {
      final response = await _apiService.getProposalStatuses();
      final statusesData = response['data'] as List;
      _statuses =
          statusesData.map((json) => ProposalStatus.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading statuses: $e');
    }
  }

  // Available Items Management
  Future<void> loadAvailableItems({
    String? search,
    int? groupId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _availableItems.clear();
    }

    _isLoadingItems = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAvailableItems(
        search: search,
        groupId: groupId,
        perPage: 100,
      );

      final itemsData = response['data'] as List;
      final newItems =
          itemsData.map((json) => AvailableItem.fromJson(json)).toList();

      if (refresh) {
        _availableItems = newItems;
      } else {
        _availableItems.addAll(newItems);
      }
    } catch (e) {
      _error = 'Failed to load available items: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading available items: $e');
      }
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  // Load item groups
  Future<void> loadItemGroups() async {
    try {
      final response = await _apiService.getItemGroups();
      final groupsData = response['data'] as List;
      _itemGroups =
          groupsData.map((json) => AvailableItemGroup.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading item groups: $e');
      }
    }
  }

  // Proposal Items Management
  Future<bool> addProposalItem(
      int proposalId, Map<String, dynamic> itemData) async {
    try {
      await _apiService.addProposalItem(proposalId, itemData);

      // Reload proposal details to get updated items
      await loadProposalDetails(proposalId);

      return true;
    } catch (e) {
      _error = 'Failed to add item to proposal: ${e.toString()}';
      if (kDebugMode) {
        print('Error adding proposal item: $e');
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProposalItem(
      int proposalId, int itemId, Map<String, dynamic> itemData) async {
    try {
      await _apiService.updateProposalItem(proposalId, itemId, itemData);

      // Reload proposal details to get updated items
      await loadProposalDetails(proposalId);

      return true;
    } catch (e) {
      _error = 'Failed to update proposal item: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating proposal item: $e');
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProposalItem(int proposalId, int itemId) async {
    try {
      await _apiService.deleteProposalItem(proposalId, itemId);

      // Reload proposal details to get updated items
      await loadProposalDetails(proposalId);

      return true;
    } catch (e) {
      _error = 'Failed to delete proposal item: ${e.toString()}';
      if (kDebugMode) {
        print('Error deleting proposal item: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Clear selected proposal
  void clearSelectedProposal() {
    _selectedProposal = null;
    notifyListeners();
  }

  // Get proposal by ID from cache
  Proposal? getProposalById(int id) {
    try {
      return _proposals.firstWhere((proposal) => proposal.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get status by ID
  ProposalStatus? getStatusById(int id) {
    try {
      return _statuses.firstWhere((status) => status.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get item group by ID
  AvailableItemGroup? getItemGroupById(int id) {
    try {
      return _itemGroups.firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }
}
