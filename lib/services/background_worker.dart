import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/reminder_model.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'local_data_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: false,
      autoStartOnBoot: false,
    ),
  );
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  Timer.periodic(const Duration(minutes: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update notification if needed
      }
    }

    try {
      
      final reminderService = ReminderService();
      final reminder = await reminderService.getReminder();
      
      if (reminder == null || !reminder.enabled) {
        timer.cancel();
        service.stopSelf();
        return;
      }

      final dataService = LocalDataService();
      await dataService.refreshData();
      final response = await dataService.searchRegister(reminder.registerNumber);

      if (response.found && response.results.isNotEmpty) {
        final filteredResults = response.results.where((result) {
          if (reminder.dateFrom == null && reminder.dateTo == null) {
            return true;
          }

          try {
            final dateParts = result.examDate.split('-');
            if (dateParts.length == 3) {
              final examDate = DateTime(
                int.parse(dateParts[2]),
                int.parse(dateParts[1]),
                int.parse(dateParts[0]),
              );

              if (reminder.dateFrom != null && examDate.isBefore(reminder.dateFrom!)) {
                return false;
              }
              if (reminder.dateTo != null && examDate.isAfter(reminder.dateTo!)) {
                return false;
              }
              return true;
            }
          } catch (e) {
            // Ignore date parsing errors
          }
          return true;
        }).toList();

        if (filteredResults.isNotEmpty) {
          final result = filteredResults.first;
          final notificationService = NotificationService();
          await notificationService.initialize();
          await notificationService.showSeatFoundNotification(
            registerNumber: result.registerNo,
            hall: result.hall,
            seat: result.seat,
            examDate: result.examDate,
            session: result.session,
          );

          final updatedReminder = ReminderSettings(
            registerNumber: reminder.registerNumber,
            dateFrom: reminder.dateFrom,
            dateTo: reminder.dateTo,
            enabled: false,
            lastCheckTime: DateTime.now(),
          );
          await reminderService.saveReminder(updatedReminder);
          
          timer.cancel();
          service.stopSelf();
        }
      }

      await reminderService.updateLastCheckTime();
    } catch (e) {
      // Ignore errors and retry on next cycle
    }
  });
}
