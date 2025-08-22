import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  String? _error;

  String? get error => _error;

  // Tickets endpoints (matching TicketController)
  Future<Map<String, dynamic>> getTickets({
    int page = 1,
    int perPage = 20,
    String? search,
    int? statusId,
    int? priorityId,
    int? categoryId,
    int? clientId,
    String? modelType,
    int? modelId,
    String? startDate,
    String? endDate,
    String? createdStartDate,
    String? createdEndDate,
    bool? overdue,
    bool? dueSoon,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    bool myTicketsOnly = false,
  }) async {
    try {
      final response = await _dio.get('/tickets', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null) 'search': search,
        if (statusId != null) 'status_id': statusId,
        if (priorityId != null) 'priority_id': priorityId,
        if (categoryId != null) 'category_id': categoryId,
        if (clientId != null) 'client_id': clientId,
        if (modelType != null) 'model_type': modelType,
        if (modelId != null) 'model_id': modelId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (createdStartDate != null) 'created_start_date': createdStartDate,
        if (createdEndDate != null) 'created_end_date': createdEndDate,
        if (overdue != null) 'overdue': overdue,
        if (dueSoon != null) 'due_soon': dueSoon,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'my_tickets_only': myTicketsOnly,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicket(int id) async {
    try {
      final response = await _dio.get('/tickets/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tickets', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTicket(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tickets/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTicket(int id) async {
    try {
      final response = await _dio.delete('/tickets/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> replyToTicket(int id, String message) async {
    try {
      final response =
          await _dio.post('/tickets/$id/reply', data: {'message': message});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changeTicketStatus(int id, int statusId) async {
    try {
      final response = await _dio
          .post('/tickets/$id/change-status', data: {'status_id': statusId});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> assignTicketStaff(
      int id, List<int> staffIds) async {
    try {
      final response = await _dio
          .post('/tickets/$id/assign-staff', data: {'staff_ids': staffIds});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeTicketStaff(
      int id, List<int> staffIds) async {
    try {
      final response = await _dio
          .post('/tickets/$id/remove-staff', data: {'staff_ids': staffIds});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketStatuses() async {
    try {
      final response = await _dio.get('/tickets/statuses');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketPriorities() async {
    try {
      final response = await _dio.get('/tickets/priorities');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketFormData() async {
    try {
      final response = await _dio.get('/tickets/form-data');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketClients() async {
    try {
      final response = await _dio.get('/tickets/clients');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketStaffMembers() async {
    try {
      final response = await _dio.get('/tickets/staff-members');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketStatistics() async {
    try {
      final response = await _dio.get('/tickets/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Todo endpoints (matching TodoController)
  Future<Map<String, dynamic>> getTodos({
    int page = 1,
    int perPage = 50,
    String? search,
    int? priorityId,
    int? statusId,
    bool? completed,
    String? date,
    String? startDate,
    String? endDate,
    bool overdue = false,
    bool today = false,
    bool thisWeek = false,
    String sortBy = 'default',
    String sortOrder = 'asc',
    bool myTodosOnly = true,
  }) async {
    try {
      final response = await _dio.get('/todos', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (priorityId != null) 'priority_id': priorityId,
        if (statusId != null) 'status_id': statusId,
        if (completed != null) 'completed': completed,
        if (date != null) 'date': date,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'overdue': overdue,
        'today': today,
        'this_week': thisWeek,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'my_todos_only': myTodosOnly,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTodo(int id) async {
    try {
      final response = await _dio.get('/todos/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTodo(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/todos', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTodo(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/todos/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTodo(int id) async {
    try {
      final response = await _dio.delete('/todos/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markTodoCompleted(int id) async {
    try {
      final response = await _dio.post('/todos/$id/mark-completed');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markTodoIncomplete(int id) async {
    try {
      final response = await _dio.post('/todos/$id/mark-incomplete');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reorderTodos(
      List<Map<String, dynamic>> todos) async {
    try {
      final response =
          await _dio.post('/todos/reorder', data: {'todos': todos});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTodoPriorities() async {
    try {
      final response = await _dio.get('/todos/priorities');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTodoStatistics() async {
    try {
      final response = await _dio.get('/todos/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
          final token = await _storage.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiry and refresh
          if (error.response?.statusCode == 401) {
            // Try to refresh token
            if (!_storage.isRefreshTokenExpired()) {
              try {
                await refreshToken();

                // Retry the original request
                final token = await _storage.getAuthToken();
                if (token != null) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $token';
                  final response = await _dio.fetch(error.requestOptions);
                  handler.resolve(response);
                  return;
                }
              } catch (e) {
                // Refresh failed, clear auth data
                await _storage.clearAuthData();
              }
            } else {
              // Refresh token is also expired, clear auth data
              await _storage.clearAuthData();
            }
          }

          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  // Authentication methods (matching AuthController)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      // Check if login was successful
      if (response.data['success'] == true) {
        // Save complete authentication response
        await _storage.saveAuthResponse(response.data);
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post('/auth/logout');

      // Clear all stored authentication data
      await _storage.clearAuthData();

      return response.data;
    } catch (e) {
      // Clear auth data even if logout request fails
      await _storage.clearAuthData();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      // Check if refresh was successful
      if (response.data['success'] == true) {
        // Save updated authentication response
        await _storage.saveAuthResponse(response.data);
      }

      return response.data;
    } catch (e) {
      // If refresh fails, clear auth data
      await _storage.clearAuthData();
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Dashboard data (matching DashboardController)
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('/dashboard');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // App settings from dashboard
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final response = await _dio.get('/app-settings');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Theme settings
  Future<Map<String, dynamic>> getThemeSettings() async {
    try {
      final response = await _dio.get('/theme-settings');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Content management
  Future<Map<String, dynamic>> getAppContent() async {
    try {
      final response = await _dio.get('/app-content');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Clients (CustomerController in your module)
  Future<Map<String, dynamic>> getClients({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final response = await _dio.get('/clients', queryParameters: {
        'page': page,
        'per_page': limit,
        if (search != null) 'search': search,
        if (status != null) 'status': status,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/clients', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateClient(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/clients/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteClient(int id) async {
    try {
      final response = await _dio.delete('/clients/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClient(int id) async {
    try {
      final response = await _dio.get('/clients/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Leads (matching LeadController)
  Future<Map<String, dynamic>> getLeads({
    int page = 1,
    int per_page = 50,
    String? search,
    String? status_id,
  }) async {
    try {
      final response = await _dio.get('/leads', queryParameters: {
        'page': page,
        'per_page': per_page,
        if (search != null) 'search': search,
        if (status_id != null) 'status_id': status_id,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // getLead statistics
  Future<Map<String, dynamic>> getLeadStatistics() async {
    try {
      final response = await _dio.get('/leads/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/leads', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateLead(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/leads/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteLead(int id) async {
    try {
      final response = await _dio.delete('/leads/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLead(int id) async {
    try {
      final response = await _dio.get('/leads/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Tasks (matching TaskController)
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? priority,
    bool? myTasksOnly,
    bool? overdue,
    bool? dueToday,
    String? startDate,
    String? endDate,
    String? modelType,
    int? modelId,
    bool? isPublic,
    bool? visibleToClient,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _dio.get('/tasks', queryParameters: {
        'page': page,
        'per_page': limit,
        if (search != null) 'search': search,
        if (status != null) 'status_id': status,
        if (priority != null) 'priority_id': priority,
        if (myTasksOnly != null) 'my_tasks_only': myTasksOnly.toString(),
        if (overdue != null) 'overdue': overdue.toString(),
        if (dueToday != null) 'due_today': dueToday.toString(),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (modelType != null) 'model_type': modelType,
        if (modelId != null) 'model_id': modelId,
        if (isPublic != null) 'is_public': isPublic.toString(),
        if (visibleToClient != null)
          'visible_to_client': visibleToClient.toString(),
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTask(int id) async {
    try {
      final response = await _dio.get('/tasks/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // getTaskStatistics
  Future<Map<String, dynamic>> getTaskStatistics() async {
    try {
      final response = await _dio.get('/tasks/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tasks', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Create Checklist Item
  Future<Map<String, dynamic>> createChecklistItem(
      int taskId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/tasks/$taskId/add-checklist-item', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTask(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tasks/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTask(int id) async {
    try {
      final response = await _dio.delete('/tasks/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markTaskCompleted(int id) async {
    try {
      final response = await _dio.post('/tasks/$id/mark-completed');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTaskStatuses() async {
    try {
      final response = await _dio.get('/tasks/statuses');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTaskPriorities() async {
    try {
      final response = await _dio.get('/tasks/priorities');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStaffMembers() async {
    try {
      final response = await _dio.get('/tasks/staff-members');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChecklistItem(
      int taskId, int checklistId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('/tasks/$taskId/checklist/$checklistId', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Meetings (matching MeetingController)
  Future<Map<String, dynamic>> getMeetings(Map<String, dynamic> params) async {
    try {
      final response = await _dio.get('/meetings', queryParameters: params);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingsStatistics() async {
    final response = await _dio.get('/meetings/statistics');
    return response.data;
  }

  Future<Map<String, dynamic>> getMeeting(int id) async {
    try {
      final response = await _dio.get('/meetings/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/meetings', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMeeting(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/meetings/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMeeting(int id) async {
    try {
      final response = await _dio.delete('/meetings/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCalendarEvents(String dateString) async {
    try {
      final response = await _dio.get('/meetings/calendar/$dateString');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Notifications (matching NotificationController)
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? read,
  }) async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit,
        if (read != null) 'read': read.toString(),
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final response = await _dio.put('/notifications/$id/read');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods
  Future<String?> getAuthToken() async {
    return await _storage.getAuthToken();
  }

  // User data access methods
  int? getCurrentUserId() => _storage.getUserId();
  String? getCurrentUserName() => _storage.getUserName();
  String? getCurrentUserEmail() => _storage.getUserEmail();
  String? getCurrentUserPosition() => _storage.getUserPosition();
  String? getCurrentUserAvatar() => _storage.getUserAvatar();

  int? getCurrentBusinessId() => _storage.getBusinessId();
  String? getCurrentBusinessName() => _storage.getBusinessName();

  List<String>? getCurrentUserPermissions() => _storage.getUserPermissions();
  bool hasPermission(String permission) => _storage.hasPermission(permission);

  // Check if user is logged in
  bool isLoggedIn() {
    final token = _storage.getUserId();
    return token != null && !_storage.isTokenExpired();
  }

  // Get user role and status
  Map<String, dynamic>? getCurrentUserRole() => _storage.getUserRole();
  Map<String, dynamic>? getCurrentUserStatus() => _storage.getUserStatus();

  // Check if user has specific role
  bool hasRole(String roleName) {
    final role = getCurrentUserRole();
    return role != null && role['name'] == roleName;
  }

  // Check if user is active
  bool isUserActive() {
    final status = getCurrentUserStatus();
    return status != null && status['name'] == 'Active';
  }

  // Deals API methods
  Future<Map<String, dynamic>> getDeals({
    int page = 1,
    int perPage = 20,
    String? search,
    int? pipelineId,
    int? stageId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (pipelineId != null) {
      queryParams['pipeline_id'] = pipelineId;
    }
    if (stageId != null) {
      queryParams['stage_id'] = stageId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _dio.get('/deals', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> createDeal(Map<String, dynamic> dealData) async {
    final response = await _dio.post('/deals', data: dealData);
    return response.data;
  }

  Future<Map<String, dynamic>> getDeal(int dealId) async {
    final response = await _dio.get('/deals/$dealId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateDeal(
      int dealId, Map<String, dynamic> dealData) async {
    final response = await _dio.put('/deals/$dealId', data: dealData);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteDeal(int dealId) async {
    final response = await _dio.delete('/deals/$dealId');
    return response.data;
  }

  Future<Map<String, dynamic>> getPipelines() async {
    final response = await _dio.get('/deals/pipelines');
    return response.data;
  }

  Future<Map<String, dynamic>> getPipelineStages({int? pipelineId}) async {
    final queryParams = <String, dynamic>{};
    if (pipelineId != null) {
      queryParams['pipeline_id'] = pipelineId;
    }

    final response =
        await _dio.get('/deals/stages', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getDealsClients() async {
    final response = await _dio.get('/deals/clients');
    return response.data;
  }

  Future<Map<String, dynamic>> getDealsLeads() async {
    final response = await _dio.get('/deals/leads');
    return response.data;
  }

  Future<Map<String, dynamic>> getDealsStatistics() async {
    final response = await _dio.get('/deals/statistics');
    return response.data;
  }

  Future<Map<String, dynamic>> moveDealToStage(int dealId, int stageId) async {
    final response = await _dio.post('/deals/$dealId/move-to-stage', data: {
      'stage_id': stageId,
    });
    return response.data;
  }

  // Estimates endpoints (matching EstimateController)
  Future<Map<String, dynamic>> getEstimates({
    int page = 1,
    int perPage = 20,
    String? search,
    int? statusId,
    String? approvalStatus,
    int? clientId,
    String? modelType,
    int? modelId,
    String? startDate,
    String? endDate,
    bool? expired,
    bool? expiringSoon,
    bool? convertedToInvoice,
    double? minTotal,
    double? maxTotal,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    bool myEstimatesOnly = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'my_estimates_only': myEstimatesOnly,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (statusId != null) queryParameters['status_id'] = statusId;
      if (approvalStatus != null)
        queryParameters['approval_status'] = approvalStatus;
      if (clientId != null) queryParameters['client_id'] = clientId;
      if (modelType != null) queryParameters['model_type'] = modelType;
      if (modelId != null) queryParameters['model_id'] = modelId;
      if (startDate != null) queryParameters['start_date'] = startDate;
      if (endDate != null) queryParameters['end_date'] = endDate;
      if (expired != null) queryParameters['expired'] = expired;
      if (expiringSoon != null) queryParameters['expiring_soon'] = expiringSoon;
      if (convertedToInvoice != null)
        queryParameters['converted_to_invoice'] = convertedToInvoice;
      if (minTotal != null) queryParameters['min_total'] = minTotal;
      if (maxTotal != null) queryParameters['max_total'] = maxTotal;

      final response =
          await _dio.get('/estimates', queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEstimate(int id) async {
    try {
      final response = await _dio.get('/estimates/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createEstimate(
      Map<String, dynamic> estimateData) async {
    try {
      final response = await _dio.post('/estimates', data: estimateData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEstimate(
      int id, Map<String, dynamic> estimateData) async {
    try {
      final response = await _dio.put('/estimates/$id', data: estimateData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteEstimate(int id) async {
    try {
      final response = await _dio.delete('/estimates/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> convertEstimateToInvoice(int id) async {
    try {
      final response = await _dio.post('/estimates/$id/convert-to-invoice');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approveEstimate(int id) async {
    try {
      final response = await _dio.post('/estimates/$id/approve');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectEstimate(int id) async {
    try {
      final response = await _dio.post('/estimates/$id/reject');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEstimateStatuses() async {
    try {
      final response = await _dio.get('/estimates/statuses');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEstimateStatistics() async {
    try {
      final response = await _dio.get('/estimates/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Proposals endpoints (matching ProposalController)
  Future<Map<String, dynamic>> getProposals({
    int page = 1,
    int perPage = 20,
    String? search,
    int? statusId,
    int? clientId,
    String? modelType,
    int? modelId,
    String? startDate,
    String? endDate,
    bool? expired,
    bool? expiringSoon,
    bool? convertedToInvoice,
    double? minTotal,
    double? maxTotal,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    bool myProposalsOnly = false,
  }) async {
    try {
      final response = await _dio.get('/proposals', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null) 'search': search,
        if (statusId != null) 'status_id': statusId,
        if (clientId != null) 'client_id': clientId,
        if (modelType != null) 'model_type': modelType,
        if (modelId != null) 'model_id': modelId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (expired != null) 'expired': expired,
        if (expiringSoon != null) 'expiring_soon': expiringSoon,
        if (convertedToInvoice != null)
          'converted_to_invoice': convertedToInvoice,
        if (minTotal != null) 'min_total': minTotal,
        if (maxTotal != null) 'max_total': maxTotal,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'my_proposals_only': myProposalsOnly,
      });
      return response.data;
    } catch (e) {
      print('Error fetching proposals: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProposal(int id) async {
    try {
      final response = await _dio.get('/proposals/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProposal(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/proposals', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProposal(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/proposals/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteProposal(int id) async {
    try {
      final response = await _dio.delete('/proposals/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> convertProposalToInvoice(int id) async {
    try {
      final response = await _dio.post('/proposals/$id/convert-to-invoice');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProposalStatuses() async {
    try {
      final response = await _dio.get('/proposals/statuses');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProposalStatistics() async {
    try {
      final response = await _dio.get('/proposals/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Proposal Items Management
  Future<Map<String, dynamic>> getAvailableItems({
    int page = 1,
    int perPage = 50,
    String? search,
    int? groupId,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    try {
      final response =
          await _dio.get('/proposals/available-items', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null) 'search': search,
        if (groupId != null) 'group_id': groupId,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getItemGroups() async {
    try {
      final response = await _dio.get('/proposals/item-groups');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addProposalItem(
      int proposalId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/proposals/$proposalId/items', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProposalItem(
      int proposalId, int itemId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('/proposals/$proposalId/items/$itemId', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteProposalItem(
      int proposalId, int itemId) async {
    try {
      final response =
          await _dio.delete('/proposals/$proposalId/items/$itemId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProposalItems(int proposalId) async {
    try {
      final response = await _dio.get('/proposals/$proposalId/items');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Email Account endpoints (matching EmailAccountController)
  Future<Map<String, dynamic>> getEmailAccounts({
    int page = 1,
    int perPage = 20,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await _dio.get('/email-accounts', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null) 'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmailAccount(int id) async {
    try {
      final response = await _dio.get('/email-accounts/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createEmailAccount(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/email-accounts', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEmailAccount(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/email-accounts/$id', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteEmailAccount(int id) async {
    try {
      final response = await _dio.delete('/email-accounts/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> testEmailAccountConnection(int id) async {
    try {
      final response = await _dio.post('/email-accounts/$id/test-connection');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchEmailsFromServer(int id) async {
    try {
      final response = await _dio.post('/email-accounts/$id/fetch-emails');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmailAccountFolders(int id) async {
    try {
      final response = await _dio.get('/email-accounts/$id/folders');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createEmailAccountFolder(int id, String name) async {
    try {
      final response = await _dio.post('/email-accounts/$id/folders', data: {
        'name': name,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteEmailAccountFolder(int id, int folderId) async {
    try {
      final response = await _dio.delete('/email-accounts/$id/folders/$folderId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmailAccountStatistics() async {
    try {
      final response = await _dio.get('/email-accounts/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Email Message endpoints (matching EmailMessageController)
  Future<Map<String, dynamic>> getEmailMessages({
    int page = 1,
    int perPage = 20,
    int? accountId,
    String? folderName,
    bool? read,
    bool? favourite,
    bool? archived,
    String? search,
    String? startDate,
    String? endDate,
    String? senderEmail,
    bool? hasAttachments,
    String sortBy = 'delivery_date',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await _dio.get('/email-messages', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (accountId != null) 'account_id': accountId,
        if (folderName != null) 'folder_name': folderName,
        if (read != null) 'read': read,
        if (favourite != null) 'favourite': favourite,
        if (archived != null) 'archived': archived,
        if (search != null) 'search': search,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (senderEmail != null) 'sender_email': senderEmail,
        if (hasAttachments != null) 'has_attachments': hasAttachments,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmailMessage(int id) async {
    try {
      final response = await _dio.get('/email-messages/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendEmailMessage(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/email-messages/send', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> replyToEmailMessage(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/email-messages/$id/reply', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forwardEmailMessage(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/email-messages/$id/forward', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markEmailAsRead(int id, bool read) async {
    try {
      final response = await _dio.post('/email-messages/$id/mark-as-read', data: {
        'read': read,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markEmailAsFavourite(int id, bool favourite) async {
    try {
      final response = await _dio.post('/email-messages/$id/mark-as-favourite', data: {
        'favourite': favourite,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> archiveEmailMessage(int id, bool archived) async {
    try {
      final response = await _dio.post('/email-messages/$id/archive', data: {
        'archived': archived,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> moveEmailToFolder(int id, String folderName) async {
    try {
      final response = await _dio.post('/email-messages/$id/move-to-folder', data: {
        'folder_name': folderName,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteEmailMessage(int id) async {
    try {
      final response = await _dio.delete('/email-messages/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchEmailMessages({
    required String query,
    int page = 1,
    int perPage = 20,
    int? accountId,
    String? folder,
    String? dateFrom,
    String? dateTo,
    bool? hasAttachments,
    bool? read,
    bool? starred,
  }) async {
    try {
      final response = await _dio.get('/email-messages/search', queryParameters: {
        'query': query,
        'page': page,
        'per_page': perPage,
        if (accountId != null) 'account_id': accountId,
        if (folder != null) 'folder': folder,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (hasAttachments != null) 'has_attachments': hasAttachments,
        if (read != null) 'read': read,
        if (starred != null) 'starred': starred,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmailMessageStatistics() async {
    try {
      final response = await _dio.get('/email-messages/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Chat endpoints (matching ChatController)
  Future<Map<String, dynamic>> getChatRooms({
    int page = 1,
    int perPage = 20,
    String? search,
    String sortBy = 'updated_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await _dio.get('/chat/rooms', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null) 'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatRoom(int id) async {
    try {
      final response = await _dio.get('/chat/rooms/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createChatRoom(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/chat/rooms', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatMessages(
    int roomId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response =
          await _dio.get('/chat/rooms/$roomId/messages', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    int roomId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await _dio.post('/chat/rooms/$roomId/messages', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markChatAsRead(int roomId) async {
    try {
      final response = await _dio.post('/chat/rooms/$roomId/mark-read');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatUnreadCount() async {
    try {
      final response = await _dio.get('/chat/unread-count');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatStaffMembers() async {
    try {
      final response = await _dio.get('/chat/staff-members');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  void _handleError(DioException error) {
    try {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          String message = 'An error occurred';

          // Try to extract message from different response formats
          if (responseData is Map<String, dynamic>) {
            message = responseData['message'] ??
                responseData['error'] ??
                responseData['msg'] ??
                'An error occurred';

            // Handle validation errors
            if (responseData.containsKey('errors') &&
                responseData['errors'] is Map) {
              final errors = responseData['errors'] as Map<String, dynamic>;
              final List<String> errorMessages = [];

              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((msg) => msg.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });

              if (errorMessages.isNotEmpty) {
                message = errorMessages.first;
              }
            }
          } else if (responseData is String) {
            message = responseData;
          }

          if (statusCode == 401) {
            // Handle unauthorized access
            _storage.clearAuthToken();
            throw Exception('Session expired. Please login again.');
          } else if (statusCode == 403) {
            throw Exception('Access denied: $message');
          } else if (statusCode == 404) {
            throw Exception('Resource not found: $message');
          } else if (statusCode == 422) {
            throw Exception(message);
          } else if (statusCode == 500) {
            // Check if server error has validation details
            if (responseData is Map<String, dynamic> &&
                responseData.containsKey('errors') &&
                responseData['errors'] is Map) {
              final errors = responseData['errors'] as Map<String, dynamic>;
              final List<String> errorMessages = [];

              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((msg) => msg.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });

              if (errorMessages.isNotEmpty) {
                throw Exception(errorMessages.first);
              }
            }
            throw Exception('Server error. Please try again later.');
          }
          throw Exception(message);
        case DioExceptionType.cancel:
          throw Exception('Request cancelled.');
        case DioExceptionType.connectionError:
          throw Exception('No internet connection.');
        default:
          throw Exception('Something went wrong: ${error.message}');
      }
    } catch (e) {
      _error = e.toString();
    }
  }
}
