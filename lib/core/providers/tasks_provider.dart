import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TasksProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _statistics;

  // State variables
  List<Task> _tasks = [];
  List<TaskStatus> _statusList = [];
  List<TaskPriority> _priorities = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';
  bool _myTasksOnly = true;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Task> get tasks => _tasks;
  List<TaskStatus> get statusList => _statusList;
  List<TaskPriority> get priorities => _priorities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  String get selectedPriority => _selectedPriority;
  bool get myTasksOnly => _myTasksOnly;
  bool get hasMore => _hasMore;
  Map<String, dynamic>? get statistics => _statistics;

  // Filtered tasks
  List<Task> get filteredTasks {
    return _tasks.where((task) {
      bool matchesSearch = _searchQuery.isEmpty ||
          task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);

      bool matchesStatus = _selectedStatus == 'All' ||
          task.status!.name == _selectedStatus ||
          task.status!.id.toString() == _selectedStatus;

      bool matchesPriority = _selectedPriority == 'All' ||
          task.priority!.name == _selectedPriority ||
          task.priority!.id.toString() == _selectedPriority;

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get overdueTasks => _tasks.where((task) => task.isOverdue).length;
  int get todayTasks => _tasks
      .where((task) =>
          task.dates!.dueDate != null &&
          task.dates!.dueDate!.day == DateTime.now().day &&
          task.dates!.dueDate!.month == DateTime.now().month &&
          task.dates!.dueDate!.year == DateTime.now().year)
      .length;

  // Task count by status
  Map<String, int> get taskCountByStatus {
    Map<String, int> counts = {};
    counts['All'] = _tasks.length;

    for (var status in _statusList) {
      counts[status.name] =
          _tasks.where((task) => task.status!.id == status.id).length;
    }

    return counts;
  }

  // Load tasks from API
  Future<void> loadTasks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _tasks.clear();
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    try {
      if (refresh || _currentPage == 1) {
        _isLoading = true;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
      notifyListeners();

      print('Loading tasks - Page: $_currentPage, MyTasks: $_myTasksOnly');

      final response = await _apiService.getTasks(
        page: _currentPage,
        limit: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final data = response['data'];

        // Parse tasks
        if (data['tasks'] != null) {
          final newTasks = (data['tasks'] as List)
              .map((json) => Task.fromJson(json))
              .toList();

          if (refresh || _currentPage == 1) {
            _tasks = newTasks;
          } else {
            _tasks.addAll(newTasks);
          }

          // Check pagination
          final pagination = data['pagination'];
          if (pagination != null) {
            _hasMore = pagination['current_page'] < pagination['last_page'];
            if (_hasMore) _currentPage++;
          }

          print('Loaded ${newTasks.length} tasks. Total: ${_tasks.length}');
        }

        // Parse status list
        if (data['status_list'] != null) {
          _statusList = (data['status_list'] as List)
              .map((json) => TaskStatus.fromJson(json))
              .toList();
          print('Status List: $_statusList');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load tasks');
      }
    } catch (e) {
      print('Error loading tasks: $e');
      _error = e.toString();

      // Fallback to mock data if API fails
      if (_tasks.isEmpty) {
        _loadMockData();
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Get single task by id
  Future<Task?> getTaskById(int id) async {
    try {
      final response = await _apiService.getTask(id);
      if (response['success'] == true) {
        return Task.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load task');
      }
    } catch (e) {
      print('Error loading task: $e');
      _error = e.toString();
      return null;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _apiService.getTaskStatistics();

      if (response['success'] == true) {
        _statistics = response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to load statistics');
      }
    } catch (e) {
      print('Error loading statistics: $e');
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Search tasks
  Future<void> searchTasks(String query) async {
    _searchQuery = query;
    notifyListeners();
    await loadTasks(refresh: true);
  }

  // Filter by status
  Future<void> filterByStatus(String status) async {
    _selectedStatus = status;
    notifyListeners();
    await loadTasks(refresh: true);
  }

  // Filter by priority
  Future<void> filterByPriority(String priority) async {
    _selectedPriority = priority;
    notifyListeners();
    await loadTasks(refresh: true);
  }

  // Toggle my tasks only
  Future<void> toggleMyTasksOnly() async {
    _myTasksOnly = !_myTasksOnly;
    notifyListeners();
    await loadTasks(refresh: true);
  }

  // Mark task as completed
  Future<void> markTaskCompleted(int taskId) async {
    try {
      final response = await _apiService.markTaskCompleted(taskId);

      if (response['success'] == true) {
        // Update task in local list
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          final updatedTask = Task.fromJson(response['data']);
          _tasks[index] = updatedTask;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking task as completed: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create new task
  Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createTask(taskData);

      if (response['success'] == true) {
        // Add new task to the beginning of the list
        final newTask = Task.fromJson(response['data']);
        _tasks.insert(0, newTask);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to create task');
      }
    } catch (e) {
      print('Error creating task: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update task
  Future<bool> updateTask(int taskId, Map<String, dynamic> taskData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateTask(taskId, taskData);

      if (response['success'] == true) {
        // Update task in local list
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          final updatedTask = Task.fromJson(response['data']);
          _tasks[index] = updatedTask;
          notifyListeners();
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to update task');
      }
    } catch (e) {
      print('Error updating task: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete task
  Future<bool> deleteTask(int taskId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.deleteTask(taskId);

      if (response['success'] == true) {
        // Remove task from local list
        _tasks.removeWhere((task) => task.id == taskId);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to delete task');
      }
    } catch (e) {
      print('Error deleting task: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tasks (pagination)
  Future<void> loadMoreTasks() async {
    if (!_hasMore || _isLoadingMore) return;
    await loadTasks();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Mock data for development
  void _loadMockData() {
    _statusList = [
      TaskStatus(id: 1, name: 'To Do', color: 'info'),
      TaskStatus(id: 2, name: 'In Progress', color: 'warning'),
      TaskStatus(id: 3, name: 'Completed', color: 'success'),
      TaskStatus(id: 4, name: 'On Hold', color: 'secondary'),
    ];

    _priorities = [
      TaskPriority(id: 1, name: 'Low', color: '#28a745', sort: 1),
      TaskPriority(id: 2, name: 'Normal', color: '#6c757d', sort: 2),
      TaskPriority(id: 3, name: 'High', color: '#ffc107', sort: 3),
      TaskPriority(id: 4, name: 'Urgent', color: '#dc3545', sort: 4),
    ];

    _tasks = [
      Task(
        id: 1,
        name: 'Update CRM Dashboard',
        description: 'Implement new dashboard features and analytics',
        priority: _priorities[2], // High
        status: _statusList[1], // In Progress
        progress: 65,
        dates: TaskDates(
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          finishedDate: null,
          isOverdue: false,
          daysUntilDue: 2,
        ),
        team: [
          TaskTeamMember(
            id: 1,
            userType: 'staff',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: null,
          ),
        ],
        commentsCount: 3,
        settings: TaskSettings(
          isPublic: true,
          isPaid: false,
          visibleToClient: true,
          points: 8,
          sort: 1,
        ),
        businessId: 1,
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Task(
        id: 2,
        name: 'Fix Mobile App Bugs',
        description: 'Resolve reported issues in the mobile application',
        priority: _priorities[3], // Urgent
        status: _statusList[0], // To Do
        progress: 0,
        dates: TaskDates(
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
          finishedDate: null,
          isOverdue: false,
          daysUntilDue: 1,
        ),
        team: [
          TaskTeamMember(
            id: 2,
            userType: 'staff',
            name: 'Jane Smith',
            email: 'jane@example.com',
            avatar: null,
          ),
        ],
        commentsCount: 1,
        settings: TaskSettings(
          isPublic: false,
          isPaid: true,
          visibleToClient: false,
          points: 5,
          sort: 2,
        ),
        businessId: 1,
        createdBy: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 3,
        name: 'Client Presentation Preparation',
        description: 'Prepare slides and demo for upcoming client meeting',
        priority: _priorities[1], // Normal
        status: _statusList[2], // Completed
        progress: 100,
        dates: TaskDates(
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          finishedDate: DateTime.now().subtract(const Duration(hours: 6)),
          isOverdue: false,
          daysUntilDue: -1,
        ),
        team: [
          TaskTeamMember(
            id: 3,
            userType: 'staff',
            name: 'Mike Johnson',
            email: 'mike@example.com',
            avatar: null,
          ),
        ],
        commentsCount: 0,
        settings: TaskSettings(
          isPublic: true,
          isPaid: false,
          visibleToClient: true,
          points: 3,
          sort: 3,
        ),
        businessId: 1,
        createdBy: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    print('Loaded mock tasks: ${_tasks.length}');
  }

  // Helper methods for formatting
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Checklist methods
  Future<bool> addChecklistItem(
      int taskId, Map<String, dynamic> itemData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createChecklistItem(taskId, itemData);

      if (response['success'] == true) {
        // Reload the task to get updated checklist
        await _refreshTaskData(taskId);
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to add checklist item');
      }
    } catch (e) {
      print('Error adding checklist item: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChecklistItem(
      int taskId, int checklistItemId, Map<String, dynamic> itemData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateChecklistItem(
          taskId, checklistItemId, itemData);

      if (response['success'] == true) {
        // Reload the task to get updated checklist
        await _refreshTaskData(taskId);
        return true;
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update checklist item');
      }
    } catch (e) {
      print('Error updating checklist item: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> getTaskDetails(int taskId) async {
    try {
      final response = await _apiService.getTask(taskId);

      if (response['success'] == true) {
        return Task.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get task details');
      }
    } catch (e) {
      print('Error getting task details: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> _refreshTaskData(int taskId) async {
    try {
      final updatedTask = await getTaskDetails(taskId);
      if (updatedTask != null) {
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error refreshing task data: $e');
    }
  }
}
