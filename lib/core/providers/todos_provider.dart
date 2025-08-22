import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/api_service.dart';

class TodosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Todo> _todos = [];
  List<TodoPriority> _priorities = [];
  TodoStatistics? _statistics;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalTodos = 0;
  String? _error;

  // Filter state
  String _searchQuery = '';
  int? _selectedPriorityId;
  int? _selectedStatusId;
  bool? _completedFilter;
  String? _dateFilter;
  String? _startDate;
  String? _endDate;
  bool _overdueFilter = false;
  bool _todayFilter = false;
  bool _thisWeekFilter = false;
  String _sortBy = 'default';
  String _sortOrder = 'asc';
  bool _myTodosOnly = true;

  // UI Filter state
  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedTimeFilter;

  // Getters
  List<Todo> get todos => _todos;
  List<TodoPriority> get priorities => _priorities;
  TodoStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  int get totalTodos => _totalTodos;
  String? get error => _error;

  // Filter getters
  String get searchQuery => _searchQuery;
  int? get selectedPriorityId => _selectedPriorityId;
  int? get selectedStatusId => _selectedStatusId;
  bool? get completedFilter => _completedFilter;
  String? get dateFilter => _dateFilter;
  String? get startDate => _startDate;
  String? get endDate => _endDate;

  // UI Filter getters
  String? get selectedPriority => _selectedPriority;
  String? get selectedStatus => _selectedStatus;
  String? get selectedTimeFilter => _selectedTimeFilter;

  bool get hasActiveFilters =>
      _selectedPriority != null ||
      _selectedStatus != null ||
      _selectedTimeFilter != null ||
      _searchQuery.isNotEmpty ||
      activeFiltersCount > 0;

  // Apply UI filters
  void applyFilters({
    String? priority,
    String? status,
    String? timeFilter,
  }) {
    _selectedPriority = priority;
    _selectedStatus = status;
    _selectedTimeFilter = timeFilter;

    // Convert UI filters to API filters
    if (priority != null) {
      final priorityObj = _priorities.firstWhere(
        (p) => p.name.toLowerCase() == priority.toLowerCase(),
        orElse: () =>
            TodoPriority(id: null, name: '', color: '', level: 0, sort: 0),
      );
      _selectedPriorityId = priorityObj.id;
    } else {
      _selectedPriorityId = null;
    }

    if (status != null) {
      _completedFilter = status.toLowerCase() == 'completed';
    } else {
      _completedFilter = null;
    }

    if (timeFilter != null) {
      switch (timeFilter.toLowerCase()) {
        case 'today':
          _todayFilter = true;
          _thisWeekFilter = false;
          _overdueFilter = false;
          break;
        case 'this week':
          _todayFilter = false;
          _thisWeekFilter = true;
          _overdueFilter = false;
          break;
        case 'overdue':
          _todayFilter = false;
          _thisWeekFilter = false;
          _overdueFilter = true;
          break;
        default:
          _todayFilter = false;
          _thisWeekFilter = false;
          _overdueFilter = false;
      }
    } else {
      _todayFilter = false;
      _thisWeekFilter = false;
      _overdueFilter = false;
    }

    loadTodos(refresh: true);
  }

  // Check if any filters are active
  bool get overdueFilter => _overdueFilter;
  bool get todayFilter => _todayFilter;
  bool get thisWeekFilter => _thisWeekFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get myTodosOnly => _myTodosOnly;

  // Computed getters
  List<Todo> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList();
  List<Todo> get pendingTodos =>
      _todos.where((todo) => !todo.isCompleted).toList();
  List<Todo> get overdueTodos => _todos
      .where((todo) => todo.dateInfo.isOverdue && !todo.isCompleted)
      .toList();
  List<Todo> get todayTodos =>
      _todos.where((todo) => todo.dateInfo.isToday).toList();
  List<Todo> get thisWeekTodos =>
      _todos.where((todo) => todo.dateInfo.isThisWeek).toList();

  // Initialize provider - load initial data
  Future<void> initialize() async {
    await Future.wait([
      loadTodos(refresh: true),
      loadPriorities(),
      loadStatistics(),
    ]);
  }

  // Load todos with pagination and filters
  Future<void> loadTodos({
    bool refresh = false,
    int? targetPage,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    targetPage ??= _currentPage;

    try {
      final response = await _apiService.getTodos(
        page: targetPage,
        perPage: 50,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        priorityId: _selectedPriorityId,
        statusId: _selectedStatusId,
        completed: _completedFilter,
        date: _dateFilter,
        startDate: _startDate,
        endDate: _endDate,
        overdue: _overdueFilter,
        today: _todayFilter,
        thisWeek: _thisWeekFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        myTodosOnly: _myTodosOnly,
      );

      final todosData = response['data']['todos'] as List;
      final newTodos = todosData.map((json) => Todo.fromJson(json)).toList();

      if (refresh || targetPage == 1) {
        _todos = newTodos;
      } else {
        _todos.addAll(newTodos);
      }

      final pagination = response['data']['pagination'] ?? {};
      _currentPage = pagination['current_page'] ?? 1;
      _lastPage = pagination['last_page'] ?? 1;
      _totalTodos = pagination['total'] ?? 0;
      _hasMoreData = _currentPage < _lastPage;

      if (_hasMoreData) {
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to load todos: ${e.toString()}';
      if (kDebugMode) {
        print('Error loading todos: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (!_hasMoreData || _isLoading) return;
    await loadTodos();
  }

  // Refresh todos
  Future<void> refreshTodos() async {
    await loadTodos(refresh: true);
  }

  // Create new todo
  Future<bool> createTodo(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createTodo(data);

      if (response['success'] == true) {
        final newTodo = Todo.fromJson(response['data']);
        _todos.insert(0, newTodo);
        _totalTodos++;
        notifyListeners();

        // Reload statistics
        loadStatistics();
        return true;
      }
      return false;
    } catch (e) {
      _error = _apiService.error;
      if (kDebugMode) {
        print('Error creating todo: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Create new todo with detailed error handling
  Future<Map<String, dynamic>> createTodoWithError(
      Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createTodo(data);

      if (response['success'] == true) {
        final newTodo = Todo.fromJson(response['data']);
        _todos.insert(0, newTodo);
        _totalTodos++;
        notifyListeners();

        // Reload statistics
        loadStatistics();
        return {'success': true};
      } else {
        final errorMessage = response['message'] ?? 'Failed to create todo';
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      String errorMessage = 'Failed to create todo';

      // Extract error message from exception
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      } else {
        errorMessage = e.toString();
      }

      _error = errorMessage;
      if (kDebugMode) {
        print('Error creating todo: $e');
      }
      notifyListeners();
      return {'success': false, 'error': _apiService.error};
    }
  }

  // Update todo
  Future<bool> updateTodo(int todoId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateTodo(todoId, data);

      if (response['success'] == true) {
        final updatedTodo = Todo.fromJson(response['data']);
        final index = _todos.indexWhere((todo) => todo.id == todoId);

        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();

          // Reload statistics
          loadStatistics();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = 'Failed to update todo: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating todo: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Update todo with detailed error handling
  Future<Map<String, dynamic>> updateTodoWithError(
      int todoId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateTodo(todoId, data);

      if (response['success'] == true) {
        final updatedTodo = Todo.fromJson(response['data']);
        final index = _todos.indexWhere((todo) => todo.id == todoId);

        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();

          // Reload statistics
          loadStatistics();
          return {'success': true};
        }
      } else {
        final errorMessage = response['message'] ?? 'Failed to update todo';
        return {'success': false, 'error': errorMessage};
      }

      return {'success': false, 'error': 'Todo not found'};
    } catch (e) {
      String errorMessage = 'Failed to update todo';

      // Extract error message from exception
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      } else {
        errorMessage = e.toString();
      }

      _error = errorMessage;
      if (kDebugMode) {
        print('Error updating todo: $e');
      }
      notifyListeners();
      return {'success': false, 'error': errorMessage};
    }
  }

  // Delete todo
  Future<bool> deleteTodo(int todoId) async {
    try {
      final response = await _apiService.deleteTodo(todoId);

      if (response['success'] == true) {
        _todos.removeWhere((todo) => todo.id == todoId);
        _totalTodos--;
        notifyListeners();

        // Reload statistics
        loadStatistics();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete todo: ${e.toString()}';
      if (kDebugMode) {
        print('Error deleting todo: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Mark todo as completed
  Future<bool> markTodoCompleted(int todoId) async {
    try {
      final response = await _apiService.markTodoCompleted(todoId);

      if (response['success'] == true) {
        final updatedTodo = Todo.fromJson(response['data']);
        final index = _todos.indexWhere((todo) => todo.id == todoId);

        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();

          // Reload statistics
          loadStatistics();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = 'Failed to mark todo as completed: ${e.toString()}';
      if (kDebugMode) {
        print('Error marking todo as completed: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Mark todo as incomplete
  Future<bool> markTodoIncomplete(int todoId) async {
    try {
      final response = await _apiService.markTodoIncomplete(todoId);

      if (response['success'] == true) {
        final updatedTodo = Todo.fromJson(response['data']);
        final index = _todos.indexWhere((todo) => todo.id == todoId);

        if (index != -1) {
          _todos[index] = updatedTodo;
          notifyListeners();

          // Reload statistics
          loadStatistics();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = 'Failed to mark todo as incomplete: ${e.toString()}';
      if (kDebugMode) {
        print('Error marking todo as incomplete: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Toggle todo completion status
  Future<bool> toggleTodoCompletion(int todoId) async {
    final todo = _todos.firstWhere((t) => t.id == todoId);
    if (todo.isCompleted) {
      return await markTodoIncomplete(todoId);
    } else {
      return await markTodoCompleted(todoId);
    }
  }

  // Reorder todos (drag and drop)
  Future<bool> reorderTodos(List<Todo> reorderedTodos) async {
    try {
      // Update local state immediately for smooth UI
      final oldTodos = List<Todo>.from(_todos);
      _todos = reorderedTodos;
      notifyListeners();

      // Prepare data for API
      final todosData = reorderedTodos.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'sort': entry.key + 1, // 1-based indexing
        };
      }).toList();

      final response = await _apiService.reorderTodos(todosData);

      if (response['success'] == true) {
        return true;
      } else {
        // Revert on failure
        _todos = oldTodos;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert on error
      _error = 'Failed to reorder todos: ${e.toString()}';
      if (kDebugMode) {
        print('Error reordering todos: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Load priorities
  Future<void> loadPriorities() async {
    try {
      final response = await _apiService.getTodoPriorities();

      if (response['success'] == true) {
        final prioritiesData = response['data'] as List;
        _priorities =
            prioritiesData.map((json) => TodoPriority.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading priorities: $e');
      }
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getTodoStatistics();

      if (response['success'] == true) {
        _statistics = TodoStatistics.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading todo statistics: $e');
      }
    }
  }

  // Filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriorityFilter(int? priorityId) {
    _selectedPriorityId = priorityId;
    notifyListeners();
  }

  void setStatusFilter(int? statusId) {
    _selectedStatusId = statusId;
    notifyListeners();
  }

  void setCompletedFilter(bool? completed) {
    _completedFilter = completed;
    notifyListeners();
  }

  void setDateFilter(String? date) {
    _dateFilter = date;
    notifyListeners();
  }

  void setDateRangeFilter(String? startDate, String? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void setOverdueFilter(bool overdue) {
    _overdueFilter = overdue;
    notifyListeners();
  }

  void setTodayFilter(bool today) {
    _todayFilter = today;
    notifyListeners();
  }

  void setThisWeekFilter(bool thisWeek) {
    _thisWeekFilter = thisWeek;
    notifyListeners();
  }

  void setSortOptions(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
  }

  void setMyTodosOnly(bool myTodosOnly) {
    _myTodosOnly = myTodosOnly;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedPriorityId = null;
    _selectedStatusId = null;
    _completedFilter = null;
    _dateFilter = null;
    _startDate = null;
    _endDate = null;
    _overdueFilter = false;
    _todayFilter = false;
    _thisWeekFilter = false;
    _sortBy = 'default';
    _sortOrder = 'asc';
    notifyListeners();
  }

  // Apply filters and reload
  Future<void> refreshWithFilters() async {
    await loadTodos(refresh: true);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  TodoPriority? getPriorityById(int id) {
    try {
      return _priorities.firstWhere((priority) => priority.id == id);
    } catch (e) {
      return null;
    }
  }

  Todo? getTodoById(int id) {
    try {
      return _todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get active filters count
  int get activeFiltersCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedPriorityId != null) count++;
    if (_selectedStatusId != null) count++;
    if (_completedFilter != null) count++;
    if (_dateFilter != null) count++;
    if (_startDate != null || _endDate != null) count++;
    if (_overdueFilter) count++;
    if (_todayFilter) count++;
    if (_thisWeekFilter) count++;
    return count;
  }
}
