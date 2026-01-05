# flutter_local_notifications_ohos

OpenHarmony (OHOS) implementation of the [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) plugin.

## Features

This plugin supports the following features on OpenHarmony:

- ✅ Show basic notifications
- ✅ Show long text notifications
- ✅ Show multi-line notifications
- ✅ Schedule notifications at specific times
- ✅ Periodically show notifications
- ✅ Cancel notifications
- ✅ Get pending notification requests
- ✅ Get active notifications
- ✅ Request notification permission
- ✅ Check notification permission status

## Getting Started

### Add Permissions

Add the following permissions to your `module.json5` file:

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.NOTIFICATION_CONTROLLER",
        "reason": "$string:notification_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

### Initialize the Plugin

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize with OHOS settings
const OhosInitializationSettings initializationSettingsOhos =
    OhosInitializationSettings(
  defaultIcon: r'$media:icon',
  requestPermissionOnInit: true,
);

const InitializationSettings initializationSettings = InitializationSettings(
  ohos: initializationSettingsOhos,
);

await flutterLocalNotificationsPlugin.initialize(
  initializationSettings,
  onDidReceiveNotificationResponse: (NotificationResponse response) {
    // Handle notification tap
  },
);
```

### Show a Notification

```dart
const OhosNotificationDetails ohosNotificationDetails = OhosNotificationDetails(
  contentType: OhosNotificationContentType.basic,
  slotType: OhosNotificationSlotType.serviceInformation,
);

const NotificationDetails notificationDetails = NotificationDetails(
  ohos: ohosNotificationDetails,
);

await flutterLocalNotificationsPlugin.show(
  0, // notification id
  'Title',
  'Body',
  notificationDetails,
  payload: 'custom payload',
);
```

### Schedule a Notification

```dart
await flutterLocalNotificationsPlugin.zonedSchedule(
  0,
  'Scheduled Title',
  'Scheduled Body',
  tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
  notificationDetails,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
);
```

## Notification Types

### Basic Notification
Standard notification with title and body text.

### Long Text Notification
Expandable notification with longer content.

```dart
const OhosNotificationDetails details = OhosNotificationDetails(
  contentType: OhosNotificationContentType.longText,
  longText: 'This is a very long text that will be shown when expanded...',
  expandedTitle: 'Expanded Title',
);
```

### Multi-line Notification
Notification displaying multiple lines of text.

```dart
const OhosNotificationDetails details = OhosNotificationDetails(
  contentType: OhosNotificationContentType.multiLine,
  lines: ['Line 1', 'Line 2', 'Line 3'],
);
```

## Slot Types

OpenHarmony uses notification slots to categorize notifications:

- `socialCommunication` - For messages and social communication
- `serviceInformation` - For service information (default)
- `contentInformation` - For content information
- `liveView` - For live view notifications
- `customerService` - For customer service
- `other` - Other notification types

## Limitations

- Picture notifications require PixelMap handling which is not fully implemented yet
- Background scheduling uses setTimeout which may not be reliable when the app is completely killed. For production apps, consider using `reminderAgentManager` for more reliable scheduling.

## License

BSD-3-Clause
