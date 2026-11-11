class ReminderSettings {
  final String registerNumber;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool enabled;
  final DateTime? lastCheckTime;

  ReminderSettings({
    required this.registerNumber,
    this.dateFrom,
    this.dateTo,
    required this.enabled,
    this.lastCheckTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'registerNumber': registerNumber,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'enabled': enabled,
      'lastCheckTime': lastCheckTime?.toIso8601String(),
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      registerNumber: json['registerNumber'] ?? '',
      dateFrom: json['dateFrom'] != null ? DateTime.parse(json['dateFrom']) : null,
      dateTo: json['dateTo'] != null ? DateTime.parse(json['dateTo']) : null,
      enabled: json['enabled'] ?? false,
      lastCheckTime: json['lastCheckTime'] != null ? DateTime.parse(json['lastCheckTime']) : null,
    );
  }
}
