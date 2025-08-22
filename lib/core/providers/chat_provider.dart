import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ChatRoom> _chatRooms = [];
  List<Message> _messages = [];
  List<StaffMember> _staffMembers = [];
  ChatRoom? _currentRoom;

  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _isLoadingRooms = false;
  bool _isSendingMessage = false;
  bool _hasMoreData = true;
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  int _currentMessagePage = 1;
  int _lastPage = 1;
  int _totalRooms = 0;
  int _unreadCount = 0;
  String? _error;

  // Filter state
  String _searchQuery = '';

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<Message> get messages => _messages;
  List<StaffMember> get staffMembers => _staffMembers;
  ChatRoom? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isSendingMessage => _isSendingMessage;
  bool get hasMoreData => _hasMoreData;
  bool get hasMoreMessages => _hasMoreMessages;
  int get currentPage => _currentPage;
  int get totalRooms => _totalRooms;
  int get unreadCount => _unreadCount;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadChatRooms(),
      loadStaffMembers(),
      loadUnreadCount(),
    ]);
  }

  // Load chat rooms
  Future<void> loadChatRooms({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _chatRooms.clear();
    }

    if (!_hasMoreData || _isLoadingRooms) return;

    _isLoadingRooms = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getChatRooms(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final List<dynamic> roomsData = response['data']['rooms'] ?? [];
      final pagination = response['data']['pagination'] ?? {};

      final newRooms =
          roomsData.map((json) => ChatRoom.fromJson(json)).toList();

      if (refresh) {
        _chatRooms = newRooms;
      } else {
        _chatRooms.addAll(newRooms);
      }

      _currentPage = pagination['current_page'] ?? 1;
      _lastPage = pagination['last_page'] ?? 1;
      _totalRooms = pagination['total'] ?? 0;
      _hasMoreData = _currentPage < _lastPage;

      if (_hasMoreData) _currentPage++;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chat rooms: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  // Load next page of chat rooms
  Future<void> loadNextPage() async {
    if (_hasMoreData && !_isLoadingRooms) {
      await loadChatRooms();
    }
  }

  // Refresh chat rooms
  Future<void> refreshChatRooms() async {
    await loadChatRooms(refresh: true);
  }

  // Load messages for a specific room
  Future<void> loadMessages(int roomId, {bool refresh = false}) async {
    if (refresh) {
      _currentMessagePage = 1;
      _hasMoreMessages = true;
      _messages.clear();
    }

    if (!_hasMoreMessages || _isLoadingMessages) return;

    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getChatMessages(
        roomId,
        page: _currentMessagePage,
      );

      final List<dynamic> messagesData = response['data']['messages'] ?? [];
      final pagination = response['data']['pagination'] ?? {};

      final newMessages =
          messagesData.map((json) => Message.fromJson(json)).toList();

      if (refresh) {
        _messages = newMessages;
      } else {
        // Insert older messages at the beginning
        _messages.insertAll(0, newMessages);
      }

      _currentMessagePage = pagination['current_page'] ?? 1;
      _hasMoreMessages = pagination['has_more'] ?? false;

      if (_hasMoreMessages) _currentMessagePage++;

      // Mark messages as read
      await markAsRead(roomId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Load next page of messages
  Future<void> loadNextMessages() async {
    if (_currentRoom != null && _hasMoreMessages && !_isLoadingMessages) {
      await loadMessages(_currentRoom!.id);
    }
  }

  // Send a message
  Future<bool> sendMessage(int roomId, String messageText,
      {String type = 'text'}) async {
    if (messageText.trim().isEmpty) return false;

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(roomId, {
        'message': messageText.trim(),
        'type': type,
      });

      final messageData = response['data'];
      final newMessage = Message.fromJson(messageData);

      // Add the new message to the list
      _messages.add(newMessage);

      // Update the last message in the room
      final roomIndex = _chatRooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        _chatRooms[roomIndex] = ChatRoom.fromJson({
          ..._chatRooms[roomIndex].toJson(),
          'last_message': newMessage.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $e');
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markAsRead(int roomId) async {
    try {
      await _apiService.markChatAsRead(roomId);

      // Update unread count for the room
      final roomIndex = _chatRooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        _chatRooms[roomIndex] = ChatRoom.fromJson({
          ..._chatRooms[roomIndex].toJson(),
          'unread_count': 0,
        });
      }

      // Refresh unread count
      await loadUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.getChatUnreadCount();
      _unreadCount = response['data']['unread_count'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  // Load staff members for chat
  Future<void> loadStaffMembers() async {
    try {
      final response = await _apiService.getChatStaffMembers();
      final List<dynamic> staffData = response['data'] ?? [];
      _staffMembers =
          staffData.map((json) => StaffMember.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading staff members: $e');
    }
  }

  // Create a new chat room
  Future<bool> createChatRoom(String name, List<int> participantIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createChatRoom({
        'name': name.trim(),
        'participants': participantIds,
      });

      final roomData = response['data'];
      final newRoom = ChatRoom.fromJson(roomData);

      // Add the new room to the beginning of the list
      _chatRooms.insert(0, newRoom);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating chat room: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set current room
  void setCurrentRoom(ChatRoom? room) {
    _currentRoom = room;
    if (room != null) {
      // Load messages for the room
      loadMessages(room.id, refresh: true);
    } else {
      _messages.clear();
    }
    notifyListeners();
  }

  // Search chat rooms
  void searchChatRooms(String query) {
    _searchQuery = query;
    loadChatRooms(refresh: true);
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    loadChatRooms(refresh: true);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get room by ID
  ChatRoom? getRoomById(int id) {
    try {
      return _chatRooms.firstWhere((room) => room.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total unread count across all rooms
  int get totalUnreadCount {
    return _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  // Check if there are any unread messages
  bool get hasUnreadMessages => totalUnreadCount > 0;
}
