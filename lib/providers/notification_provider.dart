import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettings {
  final bool showInApp;
  final bool showSystem;

  NotificationSettings({
    required this.showInApp,
    required this.showSystem,
  });

  NotificationSettings copyWith({
    bool? showInApp,
    bool? showSystem,
  }) {
    return NotificationSettings(
      showInApp: showInApp ?? this.showInApp,
      showSystem: showSystem ?? this.showSystem,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier()
      : super(NotificationSettings(showInApp: true, showSystem: true));

  void toggleInApp(bool value) {
    state = state.copyWith(showInApp: value);
  }

  void toggleSystem(bool value) {
    state = state.copyWith(showSystem: value);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});
