import 'package:flutter/material.dart';

/// Lightweight app notification stored as Map in Hive
/// Avoids codegen by persisting primitive types only
class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationLevel level;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? route;
  final Map<String, dynamic>? params;
  final String? uniqueKey; // for dedup (e.g., budget-80-<id>-<period>)

  AppNotification({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.route,
    this.params,
    this.uniqueKey,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    level: level,
    title: title,
    message: message,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    route: route,
    params: params,
    uniqueKey: uniqueKey,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'level': level.name,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'route': route,
    'params': params,
    'uniqueKey': uniqueKey,
  };

  static AppNotification fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    type: NotificationType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => NotificationType.system,
    ),
    level: NotificationLevel.values.firstWhere(
      (e) => e.name == map['level'],
      orElse: () => NotificationLevel.info,
    ),
    title: map['title'] as String,
    message: map['message'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    isRead: (map['isRead'] as bool?) ?? false,
    route: map['route'] as String?,
    params: (map['params'] as Map?)?.cast<String, dynamic>(),
    uniqueKey: map['uniqueKey'] as String?,
  );
}

enum NotificationType { budget, transaction, system }

enum NotificationLevel { info, success, warning, error }

IconData iconForNotification(NotificationType type) {
  switch (type) {
    case NotificationType.budget:
      return Icons.pie_chart_outline;
    case NotificationType.transaction:
      return Icons.receipt_long;
    case NotificationType.system:
      return Icons.notifications_none;
  }
}
