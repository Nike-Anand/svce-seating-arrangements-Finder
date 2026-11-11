import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/reminder_model.dart';

class ReminderService {
  static const String _reminderKey = 'reminder_settings';

  Future<void> saveReminder(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderKey, json.encode(settings.toJson()));

    if (settings.enabled) {
      await _startBackgroundService();
    } else {
      await _stopBackgroundService();
    }
  }

  Future<ReminderSettings?> getReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_reminderKey);
    
    if (jsonString == null) return null;
    
    try {
      return ReminderSettings.fromJson(json.decode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> cancelReminder() async {
    await _stopBackgroundService();
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> _stopBackgroundService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  Future<void> updateLastCheckTime() async {
    final reminder = await getReminder();
    if (reminder != null) {
      final updated = ReminderSettings(
        registerNumber: reminder.registerNumber,
        dateFrom: reminder.dateFrom,
        dateTo: reminder.dateTo,
        enabled: reminder.enabled,
        lastCheckTime: DateTime.now(),
      );
      await saveReminder(updated);
    }
  }

  Future<bool> hasFirstLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_launched') ?? false;
  }

  Future<void> setFirstLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_launched', true);
  }
}
