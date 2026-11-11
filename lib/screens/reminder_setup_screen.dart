import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../services/local_data_service.dart';

class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({super.key});

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  final TextEditingController _registerController = TextEditingController();
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();
  
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingReminder();
  }

  Future<void> _loadExistingReminder() async {
    final reminder = await _reminderService.getReminder();
    if (reminder != null) {
      setState(() {
        _registerController.text = reminder.registerNumber;
        _dateFrom = reminder.dateFrom;
        _dateTo = reminder.dateTo;
        _isEnabled = reminder.enabled;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates for testing
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  Future<void> _saveReminder() async {
    final registerNo = _registerController.text.trim();
    
    if (registerNo.isEmpty) {
      _showError('Please enter your register number');
      return;
    }

    // Request notification permission
    final hasPermission = await _notificationService.requestPermission();
    if (!hasPermission) {
      _showError('Notification permission is required for reminders');
      return;
    }

    final reminder = ReminderSettings(
      registerNumber: registerNo,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      enabled: _isEnabled,
    );

    await _reminderService.saveReminder(reminder);

    if (_isEnabled) {
      await _performImmediateCheck(registerNo);
      
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
      
      await _notificationService.showReminderSetNotification();
      _showSuccess('Reminder set successfully! We\'ll notify you when your seat is found.');
    } else {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
      }
      _showSuccess('Reminder disabled');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _performImmediateCheck(String registerNo) async {
    try {
      // Import LocalDataService
      final dataService = LocalDataService();
      
      // Search for the register number in existing data
      final response = await dataService.searchRegister(registerNo);
      
      if (response.found && response.results.isNotEmpty) {
        // Filter by date range if specified
        final filteredResults = response.results.where((result) {
          if (_dateFrom == null && _dateTo == null) {
            return true;
          }

          try {
            // Parse date from examDate (format: "DD-MM-YYYY")
            final dateParts = result.examDate.split('-');
            if (dateParts.length == 3) {
              final examDate = DateTime(
                int.parse(dateParts[2]), // year
                int.parse(dateParts[1]), // month
                int.parse(dateParts[0]), // day
              );

              if (_dateFrom != null && examDate.isBefore(_dateFrom!)) {
                return false;
              }
              if (_dateTo != null && examDate.isAfter(_dateTo!)) {
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
          // Send notification immediately
          final result = filteredResults.first;
          await _notificationService.showSeatFoundNotification(
            registerNumber: result.registerNo,
            hall: result.hall,
            seat: result.seat,
            examDate: result.examDate,
            session: result.session,
          );
          
          // Disable reminder since seat was found
          final updatedReminder = ReminderSettings(
            registerNumber: registerNo,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            enabled: false,
            lastCheckTime: DateTime.now(),
          );
          await _reminderService.saveReminder(updatedReminder);
        }
      }
    } catch (e) {
      // Ignore errors, background service will retry
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Reminder'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reminder Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _registerController,
                      decoration: const InputDecoration(
                        labelText: 'Register Number',
                        hintText: 'e.g., 22XXXXX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(context, true),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _dateFrom != null
                                  ? DateFormat('dd-MM-yyyy').format(_dateFrom!)
                                  : 'From Date (Optional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(context, false),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _dateTo != null
                                  ? DateFormat('dd-MM-yyyy').format(_dateTo!)
                                  : 'To Date (Optional)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Reminder'),
                      subtitle: const Text('Get notified when your seat is found'),
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• The app will check for your seat assignment every 15 minutes'),
                    Text('• You\'ll receive a notification when your seat is found'),
                    Text('• Date range is optional - leave empty to check all dates'),
                    Text('• Reminder will automatically stop after finding your seat'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save Reminder', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }
}
