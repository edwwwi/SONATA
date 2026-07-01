class NotificationSettings {
  final bool telegramEnabled;
  final String? telegramBotToken;
  final String? telegramChatId;

  NotificationSettings({
    this.telegramEnabled = false,
    this.telegramBotToken,
    this.telegramChatId,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      telegramEnabled: (map['telegram_enabled'] as int?) == 1,
      telegramBotToken: map['telegram_bot_token'] as String?,
      telegramChatId: map['telegram_chat_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'telegram_enabled': telegramEnabled ? 1 : 0,
      'telegram_bot_token': telegramBotToken,
      'telegram_chat_id': telegramChatId,
    };
  }

  NotificationSettings copyWith({
    bool? telegramEnabled,
    String? telegramBotToken,
    String? telegramChatId,
  }) {
    return NotificationSettings(
      telegramEnabled: telegramEnabled ?? this.telegramEnabled,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
    );
  }
}
