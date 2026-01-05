import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

import 'model/initialization_settings.dart';
import 'model/notification_details.dart';

export 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// OpenHarmony (OHOS) implementation of the flutter_local_notifications plugin.
class OhosFlutterLocalNotificationsPlugin
    extends FlutterLocalNotificationsPlatform {
  /// Constructs an instance of [OhosFlutterLocalNotificationsPlugin].
  OhosFlutterLocalNotificationsPlugin()
      : _channel = const MethodChannel(
          'dexterous.com/flutter/local_notifications',
        );

  /// Constructor for testing purposes.
  @visibleForTesting
  OhosFlutterLocalNotificationsPlugin.private(MethodChannel channel)
      : _channel = channel;

  final MethodChannel _channel;

  /// Callback for handling notification responses.
  DidReceiveNotificationResponseCallback? _onDidReceiveNotificationResponse;

  /// Callback for handling background notification responses.
  DidReceiveBackgroundNotificationResponseCallback?
      _onDidReceiveBackgroundNotificationResponse;

  /// Registers this class as the default instance.
  static void registerWith() {
    FlutterLocalNotificationsPlatform.instance =
        OhosFlutterLocalNotificationsPlugin();
  }

  /// Initializes the plugin.
  ///
  /// Call this method on application start before using the plugin further.
  ///
  /// [settings] Contains the settings for initializing the plugin.
  ///
  /// [onDidReceiveNotificationResponse] is fired when the user selects a
  /// notification or notification action.
  ///
  /// [onDidReceiveBackgroundNotificationResponse] is fired when a notification
  /// action is triggered while the app is in the background.
  Future<bool?> initialize({
    required OhosInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    _onDidReceiveNotificationResponse = onDidReceiveNotificationResponse;
    _onDidReceiveBackgroundNotificationResponse =
        onDidReceiveBackgroundNotificationResponse;

    _channel.setMethodCallHandler(_handleMethod);

    final result = await _channel.invokeMethod<bool>('initialize', {
      'defaultIcon': settings.defaultIcon,
      'requestPermissionOnInit': settings.requestPermissionOnInit,
    });

    return result;
  }

  /// Handles method calls from the native side.
  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'didReceiveNotificationResponse':
        final Map<dynamic, dynamic> arguments =
            call.arguments as Map<dynamic, dynamic>;

        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.values[arguments['responseType'] as int],
          id: arguments['id'] as int?,
          actionId: arguments['actionId'] as String?,
          input: arguments['input'] as String?,
          payload: arguments['payload'] as String?,
        );

        if (_onDidReceiveNotificationResponse != null) {
          _onDidReceiveNotificationResponse!(response);
        }
        break;
      default:
        break;
    }
  }

  /// Shows a notification with the given parameters.
  ///
  /// [id] is a unique identifier for the notification.
  /// [title] is the title of the notification.
  /// [body] is the body text of the notification.
  /// [notificationDetails] contains OHOS-specific notification settings.
  /// [payload] is optional data to be passed when the notification is tapped.
  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
    OhosNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    validateId(id);
    await _channel.invokeMethod<void>('show', <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      ...?notificationDetails?.toJson(),
    });
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Schedules a notification to be shown at the specified date and time.
  ///
  /// [id] is a unique identifier for the notification.
  /// [title] is the title of the notification.
  /// [body] is the body text of the notification.
  /// [scheduledDate] is when the notification should be shown.
  /// [notificationDetails] contains OHOS-specific notification settings.
  /// [payload] is optional data to be passed when the notification is tapped.
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required DateTime scheduledDate,
    OhosNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    validateId(id);
    await _channel.invokeMethod<void>('zonedSchedule', <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'scheduledDateTime': scheduledDate.millisecondsSinceEpoch,
      'payload': payload,
      ...?notificationDetails?.toJson(),
    });
  }

  @override
  Future<void> periodicallyShow({
    required int id,
    String? title,
    String? body,
    required RepeatInterval repeatInterval,
  }) async {
    validateId(id);
    await _channel.invokeMethod<void>('periodicallyShow', <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'repeatInterval': repeatInterval.index,
    });
  }

  @override
  Future<void> periodicallyShowWithDuration({
    required int id,
    String? title,
    String? body,
    required Duration repeatDurationInterval,
  }) async {
    validateId(id);
    await _channel.invokeMethod<void>(
      'periodicallyShowWithDuration',
      <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'repeatDurationMilliseconds': repeatDurationInterval.inMilliseconds,
      },
    );
  }

  @override
  Future<void> cancel({required int id}) async {
    validateId(id);
    await _channel.invokeMethod<void>('cancel', id);
  }

  @override
  Future<void> cancelAll() async {
    await _channel.invokeMethod<void>('cancelAll');
  }

  @override
  Future<void> cancelAllPendingNotifications() async {
    await _channel.invokeMethod<void>('cancelAllPendingNotifications');
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('pendingNotificationRequests');

    if (result == null) {
      return <PendingNotificationRequest>[];
    }

    return result.map((dynamic item) {
      final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;
      return PendingNotificationRequest(
        map['id'] as int,
        map['title'] as String?,
        map['body'] as String?,
        map['payload'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('getActiveNotifications');

    if (result == null) {
      return <ActiveNotification>[];
    }

    return result.map((dynamic item) {
      final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;
      return ActiveNotification(
        id: map['id'] as int?,
        title: map['title'] as String?,
        body: map['body'] as String?,
        payload: map['payload'] as String?,
      );
    }).toList();
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    final Map<dynamic, dynamic>? result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('getNotificationAppLaunchDetails');

    if (result == null) {
      return null;
    }

    final bool didLaunch = result['didNotificationLaunchApp'] as bool? ?? false;

    NotificationResponse? notificationResponse;
    if (result['notificationResponse'] != null) {
      final Map<dynamic, dynamic> responseMap =
          result['notificationResponse'] as Map<dynamic, dynamic>;
      notificationResponse = NotificationResponse(
        notificationResponseType:
            NotificationResponseType.values[responseMap['responseType'] as int],
        id: responseMap['id'] as int?,
        actionId: responseMap['actionId'] as String?,
        input: responseMap['input'] as String?,
        payload: responseMap['payload'] as String?,
      );
    }

    return NotificationAppLaunchDetails(
      didLaunch,
      notificationResponse: notificationResponse,
    );
  }

  /// Requests notification permission from the user.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  /// Checks if notification permission is granted.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> isNotificationEnabled() async {
    final result = await _channel.invokeMethod<bool>('isNotificationEnabled');
    return result ?? false;
  }
}
