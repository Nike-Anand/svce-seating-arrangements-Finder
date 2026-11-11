import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/seating_models.dart';
import '../services/local_data_service.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import 'reminder_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _registerController = TextEditingController();
  final LocalDataService _dataService = LocalDataService();
  
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isAutoFetching = false;
  List<SeatingResult> _results = [];
  String? _errorMessage;
  StatsResponse? _stats;
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notification service
    await _notificationService.initialize();
    
    // Check if first launch and auto-fetch
    final hasLaunched = await _reminderService.hasFirstLaunched();
    if (!hasLaunched) {
      setState(() {
        _isAutoFetching = true;
      });
      
      await _refreshData();
      await _reminderService.setFirstLaunched();
      
      setState(() {
        _isAutoFetching = false;
      });
    } else {
      await _loadStats();
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dataService.getStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Handle error silently for stats
    }
  }

  Future<void> _search() async {
    final registerNo = _registerController.text.trim();
    if (registerNo.isEmpty) {
      _showError('Please enter a register number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final response = await _dataService.searchRegister(registerNo);
      setState(() {
        _results = response.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error searching data');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await _dataService.refreshData();
      await _loadStats();
      _showSuccess('Data refreshed successfully!');
    } catch (e) {
      _showError('Failed to refresh data');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('SVCE Seating Finder'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              final reminder = await _reminderService.getReminder();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderSetupScreen(),
                  ),
                );
              }
            },
            icon: FutureBuilder(
              future: _reminderService.getReminder(),
              builder: (context, snapshot) {
                final isActive = snapshot.data?.enabled ?? false;
                return Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (isActive)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isAutoFetching
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching latest data...'),
                  Text('This only happens on first launch', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  _buildSearchBox(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Last Updated', style: TextStyle(fontSize: 12)),
                Text(
                  _stats?.lastUpdated != null
                      ? DateTime.parse(_stats!.lastUpdated!).toString().split('.')[0]
                      : 'No data yet',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              children: [
                const Text('Total Records', style: TextStyle(fontSize: 12)),
                Text(
                  '${_stats?.totalEntries ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _registerController,
              decoration: const InputDecoration(
                hintText: 'Enter your register number (e.g., 22XXXXX)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _search,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_results.isEmpty && _registerController.text.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Results Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('The register number was not found in the seating arrangements.'),
          ],
        ),
      );
    }

    if (_results.isNotEmpty) {
      return ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(result.registerNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${result.examDate} - ${result.session}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hall/Room', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(result.hall, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Seat Number', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(result.seat, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (result.pdfUrl != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(result.pdfUrl!)),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('View Full PDF'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    return const Center(
      child: Text('Enter your register number to search for seating arrangements'),
    );
  }
}