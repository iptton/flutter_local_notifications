/// The available notification content types on OpenHarmony.
enum OhosNotificationContentType {
  /// Basic text notification.
  basic,
  
  /// Long text notification that can be expanded.
  longText,
  
  /// Multi-line notification.
  multiLine,
  
  /// Picture notification with an image.
  picture,
}

/// The notification slot types on OpenHarmony.
enum OhosNotificationSlotType {
  /// Unknown slot type.
  unknown,
  
  /// Social communication slot (for messages, etc.).
  socialCommunication,
  
  /// Service information slot.
  serviceInformation,
  
  /// Content information slot.
  contentInformation,
  
  /// Live view slot.
  liveView,
  
  /// Customer service slot.
  customerService,
  
  /// Other slot types.
  other,
}

/// Represents the notification details for OpenHarmony.
class OhosNotificationDetails {
  /// Constructs an instance of [OhosNotificationDetails].
  const OhosNotificationDetails({
    this.contentType = OhosNotificationContentType.basic,
    this.slotType = OhosNotificationSlotType.serviceInformation,
    this.icon,
    this.additionalText,
    this.briefText,
    this.expandedTitle,
    this.longText,
    this.lines,
    this.picture,
    this.autoCancel = true,
    this.badgeNumber,
    this.groupName,
    this.isCountDown = false,
    this.isStopwatch = false,
    this.showDeliveryTime = false,
  });

  /// The content type of the notification.
  final OhosNotificationContentType contentType;

  /// The slot type for the notification.
  final OhosNotificationSlotType slotType;

  /// The notification icon resource path.
  final String? icon;

  /// Additional text to display in the notification.
  final String? additionalText;

  /// Brief text for the notification.
  final String? briefText;

  /// The expanded title for long text notifications.
  final String? expandedTitle;

  /// The long text content for long text notifications.
  final String? longText;

  /// Lines of text for multi-line notifications.
  final List<String>? lines;

  /// Picture resource path for picture notifications.
  final String? picture;

  /// Whether the notification should be automatically cancelled when tapped.
  final bool autoCancel;

  /// The badge number to display on the app icon.
  final int? badgeNumber;

  /// The group name for notification grouping.
  final String? groupName;

  /// Whether to display as a countdown timer.
  final bool isCountDown;

  /// Whether to display as a stopwatch.
  final bool isStopwatch;

  /// Whether to show the delivery time.
  final bool showDeliveryTime;

  /// Converts this object to a JSON map for platform channel communication.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'contentType': contentType.index,
      'slotType': slotType.index,
      'icon': icon,
      'additionalText': additionalText,
      'briefText': briefText,
      'expandedTitle': expandedTitle,
      'longText': longText,
      'lines': lines,
      'picture': picture,
      'autoCancel': autoCancel,
      'badgeNumber': badgeNumber,
      'groupName': groupName,
      'isCountDown': isCountDown,
      'isStopwatch': isStopwatch,
      'showDeliveryTime': showDeliveryTime,
    };
  }
}
