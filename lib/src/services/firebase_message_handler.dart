import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global instance untuk background message handler
late FirebaseMessageHandler _firebaseMessageHandler;

/// Dipanggil dari main() untuk initialize Firebase messaging
void setupFirebaseMessaging() {
  _firebaseMessageHandler = FirebaseMessageHandler._();
  _firebaseMessageHandler._initialize();
}

/// Dipanggil dari session controller setelah user login
/// untuk subscribe ke topic berdasarkan role
void subscribeToFirebaseTopics(String userRole, int userId) {
  // Firebase topic subscriptions not supported on web
  if (kIsWeb) {
    debugPrint('⚠️ Skipping Firebase topic subscription on web platform');
    return;
  }
  _firebaseMessageHandler.subscribeToTopics(userRole, userId);
}

/// Dipanggil dari session controller saat logout
void unsubscribeFromTopics(String userRole, int userId) {
  // Firebase topic un-subscriptions not supported on web
  if (kIsWeb) {
    debugPrint('⚠️ Skipping Firebase topic un-subscription on web platform');
    return;
  }
  _firebaseMessageHandler.unsubscribeFromTopics(userRole, userId);
}

/// Handler untuk background messages (app terminated atau background)
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  _firebaseMessageHandler._handleRemoteMessage(message);
}

class FirebaseMessageHandler {
  FirebaseMessageHandler._();

  late FirebaseMessaging _fcm;
  late FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> _initialize() async {
    _fcm = FirebaseMessaging.instance;
    _setupLocalNotifications();
    _setupMessageHandlers();
    _requestPermissions();
  }

  void _setupLocalNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleLocalNotificationTap,
    );

    _createNotificationChannels();
  }

  void _createNotificationChannels() {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.messageId}');
      _handleRemoteMessage(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // Handle notification taps when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.messageId}');
      _handleRemoteMessageTap(message);
    });
  }

  Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User denied notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Provisional notification permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission granted');
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showNotification(
        id: message.messageId?.hashCode ?? 0,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: _encodePayload(data),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = _decodePayload(payload);
      _navigateFromNotification(data);
    } catch (e) {
      debugPrint('Error handling local notification tap: $e');
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _navigateFromNotification(message.data);
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    final moduleType = data['module'] ?? '';
    final eventType = data['event_type'] ?? '';
    final entityId = data['entity_id'] as String?;

    debugPrint(
      'Navigate from notification: module=$moduleType, type=$eventType, id=$entityId',
    );

    // TODO: Implement navigation berdasarkan module & entity_id
    // Contoh:
    // if (moduleType == 'events' && entityId != null) {
    //   NavigatorKit.push(context, EventDetailPage(eventId: int.parse(entityId)));
    // } else if (moduleType == 'services' && entityId != null) {
    //   NavigatorKit.push(context, ServiceDetailPage(serviceId: int.parse(entityId)));
    // }
  }

  void subscribeToTopics(String userRole, int userId) {
    // Subscribe ke public topics
    _fcm.subscribeToTopic('announcements');

    // Subscribe ke role-specific topics
    if (userRole.toLowerCase() == 'admin') {
      _fcm.subscribeToTopic('admin_notifications');
    } else if (userRole.toLowerCase() == 'jemaat') {
      _fcm.subscribeToTopic('jemaat_notifications');
    }

    // Subscribe ke user-specific topic untuk direct messages
    _fcm.subscribeToTopic('user_$userId');

    debugPrint(
      'Subscribed to topics: announcements, ${userRole}_notifications, user_$userId',
    );
  }

  void unsubscribeFromTopics(String userRole, int userId) {
    _fcm.unsubscribeFromTopic('announcements');
    _fcm.unsubscribeFromTopic('${userRole}_notifications');
    _fcm.unsubscribeFromTopic('user_$userId');

    debugPrint('Unsubscribed from topics');
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    payload.split('&').forEach((pair) {
      final split = pair.split('=');
      if (split.length == 2) {
        map[Uri.decodeComponent(split[0])] = Uri.decodeComponent(split[1]);
      }
    });
    return map;
  }
}
