/// Represents the settings for initializing the plugin on OpenHarmony.
class OhosInitializationSettings {
  /// Constructs an instance of [OhosInitializationSettings].
  const OhosInitializationSettings({
    this.defaultIcon,
    this.requestPermissionOnInit = true,
  });

  /// The default icon to use for notifications.
  /// 
  /// This should be a resource path like '$media:icon'.
  final String? defaultIcon;

  /// Whether to request notification permission during initialization.
  /// 
  /// Defaults to `true`.
  final bool requestPermissionOnInit;
}
