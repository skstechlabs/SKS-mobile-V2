import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic>? additionalData;
  final bool isRead;
  final int ttlDays; // Time to live in days (default 30)

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.additionalData,
    this.isRead = false,
    this.ttlDays = 30,
  });
  
  /// Check if notification has expired based on TTL
  bool get isExpired {
    final expiryDate = receivedAt.add(Duration(days: ttlDays));
    return DateTime.now().isAfter(expiryDate);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'additionalData': additionalData,
        'isRead': isRead,
        'ttlDays': ttlDays,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      ttlDays: json['ttlDays'] as int? ?? 30,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      additionalData: additionalData,
      isRead: isRead ?? this.isRead,
      ttlDays: ttlDays,
    );
  }
}

class NotificationStorageService {
  static final NotificationStorageService _instance =
      NotificationStorageService._internal();
  factory NotificationStorageService() => _instance;
  NotificationStorageService._internal();

  static const String _storageKey = 'stored_notifications';
  static const int _maxNotifications = 100; // Keep last 100 notifications

  List<NotificationModel> _notifications = [];
  final List<Function(List<NotificationModel>)> _listeners = [];

  /// Initialize and load stored notifications
  Future<void> initialize() async {
    await _loadNotifications();
    await _cleanupExpiredNotifications();
  }
  
  /// Remove expired notifications based on TTL
  Future<void> _cleanupExpiredNotifications() async {
    final initialCount = _notifications.length;
    _notifications.removeWhere((notification) => notification.isExpired);
    
    if (_notifications.length < initialCount) {
      await _saveNotifications();
      final removedCount = initialCount - _notifications.length;
      debugPrint('🗑️ Removed $removedCount expired notifications');
    }
  }

  /// Add a listener for notification changes
  void addListener(Function(List<NotificationModel>) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(Function(List<NotificationModel>) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_notifications);
    }
  }

  /// Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications = decoded
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        debugPrint('✅ Loaded ${_notifications.length} notifications from storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      _notifications = [];
    }
  }

  /// Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String notificationsJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, notificationsJson);
      debugPrint('✅ Saved ${_notifications.length} notifications to storage');
    } catch (e) {
      debugPrint('❌ Error saving notifications: $e');
    }
  }

  /// Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    // Add to beginning of list (newest first)
    _notifications.insert(0, notification);

    // Keep only last N notifications
    if (_notifications.length > _maxNotifications) {
      _notifications = _notifications.take(_maxNotifications).toList();
    }

    await _saveNotifications();
    _notifyListeners();

    debugPrint('✅ Added notification: ${notification.title}');
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      _notifyListeners();
      debugPrint('✅ Marked notification as read: $notificationId');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    _notifyListeners();
    debugPrint('✅ Marked all notifications as read');
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    _notifyListeners();
    debugPrint('✅ Deleted notification: $notificationId');
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    _notifyListeners();
    debugPrint('✅ Cleared all notifications');
  }

  /// Get all notifications (excluding expired ones)
  List<NotificationModel> getAll() {
    return List.unmodifiable(_notifications.where((n) => !n.isExpired));
  }

  /// Get unread notifications (excluding expired ones)
  List<NotificationModel> getUnread() {
    return _notifications.where((n) => !n.isRead && !n.isExpired).toList();
  }

  /// Get unread count (excluding expired ones)
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead && !n.isExpired).length;
  }
  
  /// Get notification by ID
  NotificationModel? getById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id && !n.isExpired);
    } catch (e) {
      return null;
    }
  }
}
