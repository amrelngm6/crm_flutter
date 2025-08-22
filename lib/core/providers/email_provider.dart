import 'package:flutter/foundation.dart';
import '../models/email_account.dart';
import '../models/email_message.dart';
import '../services/api_service.dart';

class EmailProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Email Accounts
  List<EmailAccount> _emailAccounts = [];
  EmailAccount? _selectedEmailAccount;
  Map<String, dynamic> _accountStatistics = {};

  // Email Messages
  List<EmailMessage> _emailMessages = [];
  EmailMessage? _selectedEmailMessage;
  Map<String, dynamic> _messageStatistics = {};

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isLoadingMessages = false;
  String? _error;

  // Pagination for accounts
  int _accountsCurrentPage = 1;
  int _accountsLastPage = 1;
  int _totalAccounts = 0;
  bool _accountsHasMoreData = true;

  // Pagination for messages
  int _messagesCurrentPage = 1;
  int _messagesLastPage = 1;
  int _totalMessages = 0;
  bool _messagesHasMoreData = true;

  // Search and filter state for accounts
  String _accountsSearchQuery = '';
  String _accountsSortBy = 'created_at';
  String _accountsSortOrder = 'desc';

  // Search and filter state for messages
  String _messagesSearchQuery = '';
  int? _selectedAccountId;
  String? _selectedFolderName;
  bool? _readFilter;
  bool? _favouriteFilter;
  bool? _archivedFilter;
  String? _startDate;
  String? _endDate;
  String? _senderEmail;
  bool? _hasAttachmentsFilter;
  String _messagesSortBy = 'delivery_date';
  String _messagesSortOrder = 'desc';

  // Getters for Email Accounts
  List<EmailAccount> get emailAccounts => _emailAccounts;
  EmailAccount? get selectedEmailAccount => _selectedEmailAccount;
  Map<String, dynamic> get accountStatistics => _accountStatistics;

  // Getters for Email Messages
  List<EmailMessage> get emailMessages => _emailMessages;
  EmailMessage? get selectedEmailMessage => _selectedEmailMessage;
  Map<String, dynamic> get messageStatistics => _messageStatistics;

  // Getters for loading states
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;

  // Getters for pagination
  int get accountsCurrentPage => _accountsCurrentPage;
  int get accountsLastPage => _accountsLastPage;
  int get totalAccounts => _totalAccounts;
  bool get accountsHasMoreData => _accountsHasMoreData;

  int get messagesCurrentPage => _messagesCurrentPage;
  int get messagesLastPage => _messagesLastPage;
  int get totalMessages => _totalMessages;
  bool get messagesHasMoreData => _messagesHasMoreData;

  // Getters for filters
  String get accountsSearchQuery => _accountsSearchQuery;
  String get accountsSortBy => _accountsSortBy;
  String get accountsSortOrder => _accountsSortOrder;

  String get messagesSearchQuery => _messagesSearchQuery;
  int? get selectedAccountId => _selectedAccountId;
  String? get selectedFolderName => _selectedFolderName;
  bool? get readFilter => _readFilter;
  bool? get favouriteFilter => _favouriteFilter;
  bool? get archivedFilter => _archivedFilter;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get senderEmail => _senderEmail;
  bool? get hasAttachmentsFilter => _hasAttachmentsFilter;
  String get messagesSortBy => _messagesSortBy;
  String get messagesSortOrder => _messagesSortOrder;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize data
  Future<void> initialize() async {
    await Future.wait([
      loadEmailAccounts(refresh: true),
      loadAccountStatistics(),
    ]);
  }

  // Load email accounts with pagination and filters
  Future<void> loadEmailAccounts({
    bool refresh = false,
    int? page,
  }) async {
    if (refresh) {
      _accountsCurrentPage = 1;
      _accountsHasMoreData = true;
    }

    if (!_accountsHasMoreData && !refresh) return;

    final targetPage = page ?? _accountsCurrentPage;

    try {
      if (refresh) {
        _isLoading = true;
      }

      final response = await _apiService.getEmailAccounts(
        page: targetPage,
        perPage: 20,
        search: _accountsSearchQuery.isNotEmpty ? _accountsSearchQuery : null,
        sortBy: _accountsSortBy,
        sortOrder: _accountsSortOrder,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> accountsJson = data['data'] ?? [];
        final List<EmailAccount> newAccounts = accountsJson
            .map((json) => EmailAccount.fromJson(json))
            .toList();

        if (refresh || targetPage == 1) {
          _emailAccounts = newAccounts;
        } else {
          _emailAccounts.addAll(newAccounts);
        }

        _accountsCurrentPage = data['current_page'] ?? 1;
        _accountsLastPage = data['last_page'] ?? 1;
        _totalAccounts = data['total'] ?? 0;
        _accountsHasMoreData = _accountsCurrentPage < _accountsLastPage;

        // Load messages for the first account if none selected
        if (_selectedEmailAccount == null && _emailAccounts.isNotEmpty) {
          _selectedEmailAccount = _emailAccounts.first;
          await loadEmailMessages(refresh: true);
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading email accounts: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load email messages with pagination and filters
  Future<void> loadEmailMessages({
    bool refresh = false,
    int? page,
  }) async {
    if (refresh) {
      _messagesCurrentPage = 1;
      _messagesHasMoreData = true;
    }

    if (!_messagesHasMoreData && !refresh) return;

    final targetPage = page ?? _messagesCurrentPage;

    try {
      if (refresh) {
        _isLoadingMessages = true;
      }

      final response = await _apiService.getEmailMessages(
        page: targetPage,
        perPage: 20,
        accountId: _selectedAccountId,
        folderName: _selectedFolderName,
        read: _readFilter,
        favourite: _favouriteFilter,
        archived: _archivedFilter,
        search: _messagesSearchQuery.isNotEmpty ? _messagesSearchQuery : null,
        startDate: _startDate,
        endDate: _endDate,
        senderEmail: _senderEmail,
        hasAttachments: _hasAttachmentsFilter,
        sortBy: _messagesSortBy,
        sortOrder: _messagesSortOrder,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> messagesJson = data['data'] ?? [];
        final List<EmailMessage> newMessages = messagesJson
            .map((json) => EmailMessage.fromJson(json))
            .toList();

        if (refresh || targetPage == 1) {
          _emailMessages = newMessages;
        } else {
          _emailMessages.addAll(newMessages);
        }

        _messagesCurrentPage = data['current_page'] ?? 1;
        _messagesLastPage = data['last_page'] ?? 1;
        _totalMessages = data['total'] ?? 0;
        _messagesHasMoreData = _messagesCurrentPage < _messagesLastPage;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading email messages: $e');
      }
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Load next page of accounts
  Future<void> loadMoreAccounts() async {
    if (_accountsHasMoreData && !_isLoading) {
      await loadEmailAccounts(page: _accountsCurrentPage + 1);
    }
  }

  // Load next page of messages
  Future<void> loadMoreMessages() async {
    if (_messagesHasMoreData && !_isLoadingMessages) {
      await loadEmailMessages(page: _messagesCurrentPage + 1);
    }
  }

  // Select email account
  void selectEmailAccount(EmailAccount account) {
    _selectedEmailAccount = account;
    _selectedAccountId = account.id;
    notifyListeners();
    loadEmailMessages(refresh: true);
  }

  // Select email message
  Future<void> selectEmailMessage(EmailMessage message) async {
    _selectedEmailMessage = message;
    notifyListeners();

    // Mark as read if not already read
    if (!message.isRead) {
      await markMessageAsRead(message.id, true);
    }
  }

  // Get email account details
  Future<void> getEmailAccountDetails(int id) async {
    try {
      _isLoadingDetails = true;
      notifyListeners();

      final response = await _apiService.getEmailAccount(id);

      if (response['success'] == true && response['data'] != null) {
        _selectedEmailAccount = EmailAccount.fromJson(response['data']);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error getting email account details: $e');
      }
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Get email message details
  Future<void> getEmailMessageDetails(int id) async {
    try {
      _isLoadingDetails = true;
      notifyListeners();

      final response = await _apiService.getEmailMessage(id);

      if (response['success'] == true && response['data'] != null) {
        _selectedEmailMessage = EmailMessage.fromJson(response['data']);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error getting email message details: $e');
      }
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Create email account
  Future<bool> createEmailAccount(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createEmailAccount(data);

      if (response['success'] == true) {
        await loadEmailAccounts(refresh: true);
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create email account';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating email account: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update email account
  Future<bool> updateEmailAccount(int id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.updateEmailAccount(id, data);

      if (response['success'] == true) {
        await loadEmailAccounts(refresh: true);
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update email account';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating email account: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete email account
  Future<bool> deleteEmailAccount(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.deleteEmailAccount(id);

      if (response['success'] == true) {
        _emailAccounts.removeWhere((account) => account.id == id);
        if (_selectedEmailAccount?.id == id) {
          _selectedEmailAccount = null;
          _emailMessages.clear();
        }
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete email account';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting email account: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Test email account connection
  Future<Map<String, dynamic>?> testEmailAccountConnection(int id) async {
    try {
      final response = await _apiService.testEmailAccountConnection(id);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing email account connection: $e');
      }
      return null;
    }
  }

  // Fetch emails from server
  Future<bool> fetchEmailsFromServer(int id) async {
    try {
      final response = await _apiService.fetchEmailsFromServer(id);

      if (response['success'] == true) {
        await loadEmailMessages(refresh: true);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch emails';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching emails from server: $e');
      }
      return false;
    }
  }

  // Mark message as read/unread
  Future<bool> markMessageAsRead(int id, bool read) async {
    try {
      final response = await _apiService.markEmailAsRead(id, read);

      if (response['success'] == true) {
        // Update local message
        final messageIndex = _emailMessages.indexWhere((msg) => msg.id == id);
        if (messageIndex != -1) {
          final updatedMessage = EmailMessage.fromJson({
            ..._emailMessages[messageIndex].toJson(),
            'is_read': read,
          });
          _emailMessages[messageIndex] = updatedMessage;
          
          if (_selectedEmailMessage?.id == id) {
            _selectedEmailMessage = updatedMessage;
          }
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as read: $e');
      }
      return false;
    }
  }

  // Mark message as favourite/unfavourite
  Future<bool> markMessageAsFavourite(int id, bool favourite) async {
    try {
      final response = await _apiService.markEmailAsFavourite(id, favourite);

      if (response['success'] == true) {
        // Update local message
        final messageIndex = _emailMessages.indexWhere((msg) => msg.id == id);
        if (messageIndex != -1) {
          final updatedMessage = EmailMessage.fromJson({
            ..._emailMessages[messageIndex].toJson(),
            'is_starred': favourite,
          });
          _emailMessages[messageIndex] = updatedMessage;
          
          if (_selectedEmailMessage?.id == id) {
            _selectedEmailMessage = updatedMessage;
          }
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as favourite: $e');
      }
      return false;
    }
  }

  // Archive/unarchive message
  Future<bool> archiveMessage(int id, bool archived) async {
    try {
      final response = await _apiService.archiveEmailMessage(id, archived);

      if (response['success'] == true) {
        // Update local message
        final messageIndex = _emailMessages.indexWhere((msg) => msg.id == id);
        if (messageIndex != -1) {
          final updatedMessage = EmailMessage.fromJson({
            ..._emailMessages[messageIndex].toJson(),
            'is_archived': archived,
          });
          _emailMessages[messageIndex] = updatedMessage;
          
          if (_selectedEmailMessage?.id == id) {
            _selectedEmailMessage = updatedMessage;
          }
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving message: $e');
      }
      return false;
    }
  }

  // Delete email message
  Future<bool> deleteEmailMessage(int id) async {
    try {
      final response = await _apiService.deleteEmailMessage(id);

      if (response['success'] == true) {
        _emailMessages.removeWhere((message) => message.id == id);
        if (_selectedEmailMessage?.id == id) {
          _selectedEmailMessage = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting email message: $e');
      }
      return false;
    }
  }

  // Load account statistics
  Future<void> loadAccountStatistics() async {
    try {
      final response = await _apiService.getEmailAccountStatistics();
      if (response['success'] == true && response['data'] != null) {
        _accountStatistics = response['data'];
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading account statistics: $e');
      }
    }
  }

  // Load message statistics
  Future<void> loadMessageStatistics() async {
    try {
      final response = await _apiService.getEmailMessageStatistics();
      if (response['success'] == true && response['data'] != null) {
        _messageStatistics = response['data'];
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading message statistics: $e');
      }
    }
  }

  // Search emails
  Future<void> searchEmailMessages(String query) async {
    _messagesSearchQuery = query;
    await loadEmailMessages(refresh: true);
  }

  // Search accounts
  Future<void> searchEmailAccounts(String query) async {
    _accountsSearchQuery = query;
    await loadEmailAccounts(refresh: true);
  }

  // Filter messages
  void setMessageFilters({
    int? accountId,
    String? folderName,
    bool? read,
    bool? favourite,
    bool? archived,
    String? startDate,
    String? endDate,
    String? senderEmail,
    bool? hasAttachments,
  }) {
    _selectedAccountId = accountId;
    _selectedFolderName = folderName;
    _readFilter = read;
    _favouriteFilter = favourite;
    _archivedFilter = archived;
    _startDate = startDate;
    _endDate = endDate;
    _senderEmail = senderEmail;
    _hasAttachmentsFilter = hasAttachments;
    
    loadEmailMessages(refresh: true);
  }

  // Clear message filters
  void clearMessageFilters() {
    _messagesSearchQuery = '';
    _selectedAccountId = null;
    _selectedFolderName = null;
    _readFilter = null;
    _favouriteFilter = null;
    _archivedFilter = null;
    _startDate = null;
    _endDate = null;
    _senderEmail = null;
    _hasAttachmentsFilter = null;
    
    loadEmailMessages(refresh: true);
  }

  // Sort messages
  void sortMessages(String sortBy, String sortOrder) {
    _messagesSortBy = sortBy;
    _messagesSortOrder = sortOrder;
    loadEmailMessages(refresh: true);
  }

  // Sort accounts
  void sortAccounts(String sortBy, String sortOrder) {
    _accountsSortBy = sortBy;
    _accountsSortOrder = sortOrder;
    loadEmailAccounts(refresh: true);
  }
}
