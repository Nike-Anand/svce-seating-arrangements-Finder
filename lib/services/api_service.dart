import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/seating_models.dart';

class ApiService {
  // Replace with your computer's IP address or deployed server URL
  static const String baseUrl = 'http://192.168.1.100:10000'; // Change this IP

  Future<SearchResponse> searchRegister(String registerNo) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/search?register_no=$registerNo'),
    );

    if (response.statusCode == 200) {
      return SearchResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search register');
    }
  }

  Future<bool> refreshData() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/refresh'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } else {
      throw Exception('Failed to refresh data');
    }
  }

  Future<StatsResponse> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats'),
    );

    if (response.statusCode == 200) {
      return StatsResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get stats');
    }
  }
}