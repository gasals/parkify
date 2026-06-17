import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/request_models.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> fetchNotifications({int? userId, bool? isRead}) async {
    final isInitialLoad = _notifications.isEmpty;
    if (isInitialLoad) {
      _isLoading = true;
      _currentPage = 1;
      notifyListeners();
    }

    try {
      final result = await ApiService.getNotifications(
        userId: userId,
        isRead: isRead,
        page: 1,
      );
      _notifications = result.results;
      _currentPage = 1;
      _totalPages = result.count == 0 ? 1 : ((result.count + 19) ~/ 20);
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    } finally {
      if (isInitialLoad) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchNextPage({int? userId}) async {
    if (_isLoading || _currentPage >= _totalPages) return;
    _isLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      final result = await ApiService.getNotifications(
        userId: userId,
        page: _currentPage,
      );
      _notifications.addAll(result.results);
      _totalPages = result.count == 0 ? 1 : ((result.count + 19) ~/ 20);
    } catch (_) {
      _currentPage--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount(int userId) async {
    try {
      final result = await ApiService.getNotifications(
        userId: userId,
        isRead: false,
        page: 1,
        pageSize: 1,
      );
      _unreadCount = result.count;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationRead(notificationId);
      final i = _notifications.indexWhere((n) => n.id == notificationId);
      if (i != -1) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead(int userId) async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.id);
    }
  }

  Future<bool> sendToUser({
    required int userId,
    required String title,
    required String message,
    required int type,
    required int channel,
  }) async {
    try {
      await ApiService.sendNotification(
        NotificationSendRequest(
          userId: userId,
          title: title,
          message: message,
          type: type,
          channel: channel,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('sendToUser error: $e');
      return false;
    }
  }

  Future<bool> sendToAll({
    required String title,
    required String message,
    required int type,
    required int channel,
  }) async {
    try {
      await ApiService.sendNotificationToAll(
        NotificationSendRequest(
          title: title,
          message: message,
          type: type,
          channel: channel,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('sendToAll error: $e');
      return false;
    }
  }
}
